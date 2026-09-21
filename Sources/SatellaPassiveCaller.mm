#import "SatellaPassiveCaller.h"

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

#include <atomic>
#include <cstdint>
#include <cstring>

// Exact target build verified from the user-supplied 1.dylib.
// Original SHA-256: ac8587090f3421d1ef9f629f9eac543deede82d608059a347be62b6cbad161d5
// Passive SHA-256:  30de5e72b2ea1b1c2df88cdd384c67a63811157e12ae0ec5a650c8556213a642
static constexpr uintptr_t kSatellaCtorRVA = 0x847C;
static constexpr uintptr_t kSatellaInitRVA = 0x888C;
static constexpr uint64_t kKnownFatArm64Offset = 0x8000;

static const uint8_t kExpectedPassiveCtor[] = {0xC0, 0x03, 0x5F, 0xD6};
static const uint8_t kExpectedInitPrologue[] = {
    0xFC, 0x6F, 0xBA, 0xA9, 0xFA, 0x67, 0x01, 0xA9,
    0xF8, 0x5F, 0x02, 0xA9, 0xF6, 0x57, 0x03, 0xA9,
};

static std::atomic_bool gSatellaStarted{false};
static void *gOwnedHandle = nullptr;

static bool ZNHasSuffix(const char *value, const char *suffix) {
    if (!value || !suffix) return false;
    const size_t n = std::strlen(value), m = std::strlen(suffix);
    return n >= m && std::memcmp(value + n - m, suffix, m) == 0;
}

static bool ZNImageIdentityAndTextSize(const struct mach_header_64 *mh,
                                       const char *path,
                                       uint64_t *textSize) {
    if (!mh || mh->magic != MH_MAGIC_64 || !textSize) return false;

    bool identity = ZNHasSuffix(path, "/1_passive.dylib") ||
                    ZNHasSuffix(path, "/SatellaJailed_passive.dylib");
    uint64_t size = 0;

    const uint8_t *cursor = reinterpret_cast<const uint8_t *>(mh) + sizeof(*mh);
    const uint8_t *end = cursor + mh->sizeofcmds;
    for (uint32_t i = 0; i < mh->ncmds; ++i) {
        if (cursor + sizeof(struct load_command) > end) return false;
        const auto *lc = reinterpret_cast<const struct load_command *>(cursor);
        if (lc->cmdsize < sizeof(*lc) || cursor + lc->cmdsize > end) return false;

        if (lc->cmd == LC_SEGMENT_64 && lc->cmdsize >= sizeof(struct segment_command_64)) {
            const auto *seg = reinterpret_cast<const struct segment_command_64 *>(lc);
            if (std::strncmp(seg->segname, SEG_TEXT, sizeof(seg->segname)) == 0) {
                if (seg->vmaddr != 0) return false; // exact verified target layout
                size = seg->vmsize;
            }
        } else if (lc->cmd == LC_ID_DYLIB && lc->cmdsize >= sizeof(struct dylib_command)) {
            const auto *dc = reinterpret_cast<const struct dylib_command *>(lc);
            const uint32_t off = dc->dylib.name.offset;
            if (off < lc->cmdsize) {
                const char *name = reinterpret_cast<const char *>(dc) + off;
                const size_t maxLen = lc->cmdsize - off;
                if (std::memchr(name, '\0', maxLen) && ZNHasSuffix(name, "/SatellaJailed.dylib")) {
                    identity = true;
                }
            }
        }
        cursor += lc->cmdsize;
    }

    *textSize = size;
    return identity && size >= kSatellaInitRVA + sizeof(kExpectedInitPrologue);
}

struct ZNLoadedTarget {
    uintptr_t initAddress;
    bool sawMismatch;
};

static ZNLoadedTarget ZNFindLoadedTarget(void) {
    ZNLoadedTarget out = {0, false};
    const uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; ++i) {
        const struct mach_header *raw = _dyld_get_image_header(i);
        if (!raw || raw->magic != MH_MAGIC_64) continue;
        const auto *mh = reinterpret_cast<const struct mach_header_64 *>(raw);

        uint64_t textSize = 0;
        if (!ZNImageIdentityAndTextSize(mh, _dyld_get_image_name(i), &textSize)) continue;

        const uintptr_t base = reinterpret_cast<uintptr_t>(mh);
        const bool passive = std::memcmp(reinterpret_cast<const void *>(base + kSatellaCtorRVA),
                                         kExpectedPassiveCtor, sizeof(kExpectedPassiveCtor)) == 0;
        const bool initMatch = std::memcmp(reinterpret_cast<const void *>(base + kSatellaInitRVA),
                                           kExpectedInitPrologue, sizeof(kExpectedInitPrologue)) == 0;
        if (!passive || !initMatch) {
            out.sawMismatch = true;
            continue;
        }
        out.initAddress = base + kSatellaInitRVA;
        return out;
    }
    return out;
}

static bool ZNFileMatchesPassiveBuild(NSString *path) {
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
    if (!data) return false;

    const uint8_t *bytes = static_cast<const uint8_t *>(data.bytes);
    uint64_t slice = 0;
    uint32_t magic = 0;
    if (data.length >= sizeof(magic)) std::memcpy(&magic, bytes, sizeof(magic));
    if (magic != MH_MAGIC_64) {
        if (data.length < kKnownFatArm64Offset + sizeof(struct mach_header_64)) return false;
        std::memcpy(&magic, bytes + kKnownFatArm64Offset, sizeof(magic));
        if (magic != MH_MAGIC_64) return false;
        slice = kKnownFatArm64Offset;
    }

    const uint64_t required = slice + kSatellaInitRVA + sizeof(kExpectedInitPrologue);
    if (required > data.length) return false;
    return std::memcmp(bytes + slice + kSatellaCtorRVA,
                       kExpectedPassiveCtor, sizeof(kExpectedPassiveCtor)) == 0 &&
           std::memcmp(bytes + slice + kSatellaInitRVA,
                       kExpectedInitPrologue, sizeof(kExpectedInitPrologue)) == 0;
}

static NSArray<NSString *> *ZNLoadCandidates(void) {
    NSBundle *bundle = NSBundle.mainBundle;
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    if (bundle.privateFrameworksPath.length) {
        [paths addObject:[bundle.privateFrameworksPath stringByAppendingPathComponent:@"1_passive.dylib"]];
    }
    if (bundle.bundlePath.length) {
        [paths addObject:[bundle.bundlePath stringByAppendingPathComponent:@"1_passive.dylib"]];
    }
    return paths;
}

static ZNSatellaStartResult ZNResolveInit(uintptr_t *initAddress) {
    ZNLoadedTarget loaded = ZNFindLoadedTarget();
    if (loaded.initAddress) {
        *initAddress = loaded.initAddress;
        return ZNSatellaStartResultStarted;
    }

    bool foundFile = false, invalidFile = false, loadFailed = false;
    for (NSString *path in ZNLoadCandidates()) {
        if (![NSFileManager.defaultManager fileExistsAtPath:path]) continue;
        foundFile = true;

        // Critical: validate passive bytes before dlopen, otherwise a renamed
        // original Satella would execute its active constructor immediately.
        if (!ZNFileMatchesPassiveBuild(path)) {
            invalidFile = true;
            continue;
        }

        void *handle = dlopen(path.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL);
        if (!handle) {
            loadFailed = true;
            continue;
        }

        loaded = ZNFindLoadedTarget();
        if (loaded.initAddress) {
            gOwnedHandle = handle; // Keep the explicitly loaded image resident.
            *initAddress = loaded.initAddress;
            return ZNSatellaStartResultStarted;
        }
        dlclose(handle);
        invalidFile = true;
    }

    if (invalidFile || loaded.sawMismatch) return ZNSatellaStartResultTargetBuildMismatch;
    if (foundFile && loadFailed) return ZNSatellaStartResultLoadFailed;
    return ZNSatellaStartResultTargetNotFound;
}

ZNSatellaStartResult ZNSatellaPassiveStart(void) {
    if (gSatellaStarted.load(std::memory_order_acquire)) {
        return ZNSatellaStartResultAlreadyStarted;
    }

    uintptr_t initAddress = 0;
    const ZNSatellaStartResult resolved = ZNResolveInit(&initAddress);
    if (resolved != ZNSatellaStartResultStarted || !initAddress) return resolved;

    bool expected = false;
    if (!gSatellaStarted.compare_exchange_strong(expected, true, std::memory_order_acq_rel)) {
        return ZNSatellaStartResultAlreadyStarted;
    }

    void (^invoke)(void) = ^{ reinterpret_cast<void (*)(void)>(initAddress)(); };
    if (NSThread.isMainThread) invoke();
    else dispatch_sync(dispatch_get_main_queue(), invoke);
    return ZNSatellaStartResultStarted;
}

NSString *ZNSatellaStartResultString(ZNSatellaStartResult result) {
    switch (result) {
        case ZNSatellaStartResultStarted: return @"started";
        case ZNSatellaStartResultAlreadyStarted: return @"already-started";
        case ZNSatellaStartResultTargetNotFound: return @"target-not-found";
        case ZNSatellaStartResultTargetBuildMismatch: return @"target-build-mismatch";
        case ZNSatellaStartResultLoadFailed: return @"dlopen-failed";
    }
    return @"unknown";
}
