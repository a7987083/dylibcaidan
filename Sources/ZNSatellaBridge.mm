#import "ZNSatellaBridge.h"

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

static BOOL gZNSatellaStarted = NO;

typedef void (*ZNSatellaEntryFn)(void);

static BOOL ZNSatellaNameMatches(const char *imageName) {
    if (!imageName) return NO;

    NSString *path = [NSString stringWithUTF8String:imageName];
    NSString *name = path.lastPathComponent;

    return [name isEqualToString:@"SatellaJailed.dylib"] ||
           [name isEqualToString:@"SatellaJailed-passive.dylib"];
}

static const struct mach_header_64 *ZNFindSatellaHeader(void) {
    const uint32_t count = _dyld_image_count();

    for (uint32_t i = 0; i < count; i++) {
        if (!ZNSatellaNameMatches(_dyld_get_image_name(i))) {
            continue;
        }

        const struct mach_header *header = _dyld_get_image_header(i);
        if (!header || header->magic != MH_MAGIC_64) {
            continue;
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

BOOL ZNSatellaIsLoaded(void) {
    return ZNFindSatellaHeader() != NULL;
}

BOOL ZNSatellaIsStarted(void) {
    @synchronized ([NSObject class]) {
        return gZNSatellaStarted;
    }
}

BOOL ZNSatellaStart(void) {
    @synchronized ([NSObject class]) {
        if (gZNSatellaStarted) {
            NSLog(@"[SATELLA_TEST_LAUNCHER] already started");
            return YES;
        }

        const struct mach_header_64 *header = ZNFindSatellaHeader();
        if (!header) {
            NSLog(@"[SATELLA_TEST_LAUNCHER] SatellaJailed dylib is not loaded");
            return NO;
        }

        if (!ZNHeaderHasExpectedUUID(header)) {
            NSLog(@"[SATELLA_TEST_LAUNCHER] UUID mismatch; refusing RVA call");
            return NO;
        }

        const uintptr_t base = (uintptr_t)header;
        const uintptr_t entryAddress = base + kZNSatellaEntryRVA;

        NSLog(@"[SATELLA_TEST_LAUNCHER] base=0x%llx entry=0x%llx RVA=0x%llx",
              (unsigned long long)base,
              (unsigned long long)entryAddress,
              (unsigned long long)kZNSatellaEntryRVA);

        ((ZNSatellaEntryFn)entryAddress)();
        gZNSatellaStarted = YES;

        NSLog(@"[SATELLA_TEST_LAUNCHER] start complete");
        return YES;
    }
}
