#import "ZNSatellaBridge.h"

#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <stdint.h>
#import <string.h>

static const uintptr_t kZNSatellaEntryRVA = 0x888C;

// SatellaJailed.dylib UUID verified from the test artifact.
static const uint8_t kZNSatellaExpectedUUID[16] = {
    0xCC, 0xE7, 0x26, 0xAA,
    0x8E, 0x29, 0x33, 0x77,
    0xB6, 0x9B, 0x4E, 0xF9,
    0xC6, 0x1E, 0xAB, 0xC0
};

// First 8 bytes verified at RVA 0x888C in the test artifact.
static const uint8_t kZNSatellaEntryPrefix[8] = {
    0xFC, 0x6F, 0xBA, 0xA9,
    0xFA, 0x67, 0x01, 0xA9
};

static BOOL gZNSatellaStarted = NO;
static void *gZNSatellaHandle = NULL;
static NSString *gZNSatellaLastStatus = @"尚未启动";

typedef void (*ZNSatellaEntryFn)(void);

static void ZNSetStatus(NSString *status) {
    @synchronized ([NSObject class]) {
        gZNSatellaLastStatus = [status copy] ?: @"未知状态";
    }
    NSLog(@"[SATELLA_TEST_LAUNCHER_V2] %@", status);
}

NSString *ZNSatellaLastStatus(void) {
    @synchronized ([NSObject class]) {
        return [gZNSatellaLastStatus copy];
    }
}

static BOOL ZNSatellaNameMatches(const char *imageName) {
    if (!imageName) return NO;

    NSString *path = [NSString stringWithUTF8String:imageName];
    NSString *name = path.lastPathComponent;

    return ([name hasPrefix:@"SatellaJailed"] && [name hasSuffix:@".dylib"]);
}

static const struct mach_header_64 *ZNFindSatellaHeader(NSString **outPath) {
    const uint32_t count = _dyld_image_count();

    for (uint32_t i = 0; i < count; i++) {
        const char *imageName = _dyld_get_image_name(i);
        if (!ZNSatellaNameMatches(imageName)) {
            continue;
        }

        const struct mach_header *header = _dyld_get_image_header(i);
        if (!header || header->magic != MH_MAGIC_64) {
            continue;
        }

        if (outPath && imageName) {
            *outPath = [NSString stringWithUTF8String:imageName];
        }
        return (const struct mach_header_64 *)header;
    }

    return NULL;
}

static BOOL ZNHeaderHasExpectedUUID(const struct mach_header_64 *header) {
    if (!header) return NO;

    const uint8_t *cursor = (const uint8_t *)(header + 1);
    const uint8_t *end = cursor + header->sizeofcmds;

    for (uint32_t i = 0; i < header->ncmds; i++) {
        if ((size_t)(end - cursor) < sizeof(struct load_command)) {
            return NO;
        }

        const struct load_command *lc = (const struct load_command *)cursor;

        if (lc->cmdsize < sizeof(struct load_command) ||
            (size_t)(end - cursor) < lc->cmdsize) {
            return NO;
        }

        if (lc->cmd == LC_UUID) {
            if (lc->cmdsize < sizeof(struct uuid_command)) {
                return NO;
            }

            const struct uuid_command *uuid = (const struct uuid_command *)cursor;
            return memcmp(uuid->uuid,
                          kZNSatellaExpectedUUID,
                          sizeof(kZNSatellaExpectedUUID)) == 0;
        }

        cursor += lc->cmdsize;
    }

    return NO;
}

static NSArray<NSString *> *ZNSatellaCandidatePaths(void) {
    NSMutableOrderedSet<NSString *> *paths = [NSMutableOrderedSet orderedSet];

    Dl_info selfInfo = {};
    if (dladdr((const void *)&gZNSatellaStarted, &selfInfo) != 0 && selfInfo.dli_fname) {
        NSString *selfPath = [NSString stringWithUTF8String:selfInfo.dli_fname];
        NSString *dir = selfPath.stringByDeletingLastPathComponent;
        if (dir.length) {
            [paths addObject:[dir stringByAppendingPathComponent:@"SatellaJailed-passive.dylib"]];
            [paths addObject:[dir stringByAppendingPathComponent:@"SatellaJailed.dylib"]];
        }
    }

    NSString *frameworks = NSBundle.mainBundle.privateFrameworksPath;
    if (frameworks.length) {
        [paths addObject:[frameworks stringByAppendingPathComponent:@"SatellaJailed-passive.dylib"]];
        [paths addObject:[frameworks stringByAppendingPathComponent:@"SatellaJailed.dylib"]];
    }

    NSString *bundle = NSBundle.mainBundle.bundlePath;
    if (bundle.length) {
        [paths addObject:[bundle stringByAppendingPathComponent:@"SatellaJailed-passive.dylib"]];
        [paths addObject:[bundle stringByAppendingPathComponent:@"SatellaJailed.dylib"]];
    }

    NSString *execDir = NSBundle.mainBundle.executablePath.stringByDeletingLastPathComponent;
    if (execDir.length) {
        [paths addObject:[execDir stringByAppendingPathComponent:@"SatellaJailed-passive.dylib"]];
        [paths addObject:[execDir stringByAppendingPathComponent:@"SatellaJailed.dylib"]];
    }

    [paths addObject:@"/Library/MobileSubstrate/DynamicLibraries/SatellaJailed-passive.dylib"];
    [paths addObject:@"/Library/MobileSubstrate/DynamicLibraries/SatellaJailed.dylib"];

    return paths.array;
}

static const struct mach_header_64 *ZNEnsureSatellaLoaded(NSString **outPath) {
    const struct mach_header_64 *header = ZNFindSatellaHeader(outPath);
    if (header) {
        return header;
    }

    NSFileManager *fm = NSFileManager.defaultManager;
    BOOL foundCandidate = NO;
    NSString *lastError = nil;

    for (NSString *path in ZNSatellaCandidatePaths()) {
        if (![fm fileExistsAtPath:path]) {
            continue;
        }

        foundCandidate = YES;
        dlerror();
        void *handle = dlopen(path.fileSystemRepresentation, RTLD_NOW | RTLD_GLOBAL);
        if (!handle) {
            const char *error = dlerror();
            lastError = error ? [NSString stringWithUTF8String:error] : @"未知 dlopen 错误";
            continue;
        }

        gZNSatellaHandle = handle;
        header = ZNFindSatellaHeader(outPath);
        if (header) {
            ZNSetStatus([NSString stringWithFormat:@"已主动加载 Satella\n%@", path.lastPathComponent]);
            return header;
        }

        lastError = [NSString stringWithFormat:@"dlopen 成功但 dyld 未发现 %@", path.lastPathComponent];
    }

    if (!foundCandidate) {
        ZNSetStatus(@"未找到 SatellaJailed-passive.dylib\n请与启动器放同目录或 Frameworks");
    } else {
        ZNSetStatus([NSString stringWithFormat:@"Satella 加载失败\n%@", lastError ?: @"未知错误"]);
    }

    return NULL;
}

BOOL ZNSatellaIsLoaded(void) {
    return ZNFindSatellaHeader(NULL) != NULL;
}

BOOL ZNSatellaIsStarted(void) {
    @synchronized ([NSObject class]) {
        return gZNSatellaStarted;
    }
}

BOOL ZNSatellaStart(void) {
    @synchronized ([NSObject class]) {
        if (gZNSatellaStarted) {
            ZNSetStatus(@"Satella 已经调用过，无需重复启动");
            return YES;
        }

        NSString *imagePath = nil;
        const struct mach_header_64 *header = ZNEnsureSatellaLoaded(&imagePath);
        if (!header) {
            return NO;
        }

        if (!ZNHeaderHasExpectedUUID(header)) {
            ZNSetStatus([NSString stringWithFormat:@"UUID 不匹配，拒绝调用\n%@",
                         imagePath.lastPathComponent ?: @"Satella"]);
            return NO;
        }

        const uintptr_t base = (uintptr_t)header;
        const uintptr_t entryAddress = base + kZNSatellaEntryRVA;
        const uint8_t *entryBytes = (const uint8_t *)entryAddress;

        if (memcmp(entryBytes, kZNSatellaEntryPrefix, sizeof(kZNSatellaEntryPrefix)) != 0) {
            ZNSetStatus([NSString stringWithFormat:@"0x888C 入口字节不匹配\nbase=0x%llx",
                         (unsigned long long)base]);
            return NO;
        }

        ZNSetStatus([NSString stringWithFormat:@"入口校验通过，正在调用\nbase=0x%llx + 0x888C",
                     (unsigned long long)base]);

        ((ZNSatellaEntryFn)entryAddress)();
        gZNSatellaStarted = YES;

        ZNSetStatus(@"Satella 入口已调用成功\n等待其 UI / Hook 初始化");
        return YES;
    }
}
