#import "ZNMemoryEngine.h"
#import <mach/mach.h>
#import <mach-o/dyld.h>

static NSString *ZNTrim(NSString *s) {
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *ZNKR(kern_return_t kr) {
    const char *msg = mach_error_string(kr);
    return [NSString stringWithFormat:@"%s (%d)", msg ? msg : "mach error", kr];
}

@interface ZNMemoryEngine ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *freezeTable;
@property (nonatomic, strong) dispatch_queue_t freezeQueue;
@property (nonatomic, strong) dispatch_source_t freezeTimer;
@end

@implementation ZNMemoryEngine

+ (instancetype)shared {
    static ZNMemoryEngine *engine;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ engine = [[ZNMemoryEngine alloc] init]; });
    return engine;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;
    _freezeTable = [NSMutableDictionary dictionary];
    _freezeQueue = dispatch_queue_create("xyz.zonoe.neonmodifier.freeze", DISPATCH_QUEUE_SERIAL);
    _freezeTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _freezeQueue);
    dispatch_source_set_timer(_freezeTimer,
                              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)),
                              (uint64_t)(0.15 * NSEC_PER_SEC),
                              (uint64_t)(0.02 * NSEC_PER_SEC));
    __weak ZNMemoryEngine *weakSelf = self;
    dispatch_source_set_event_handler(_freezeTimer, ^{
        ZNMemoryEngine *strongSelf = weakSelf;
        if (!strongSelf) return;
        NSArray<NSDictionary<NSString *, id> *> *entries = strongSelf.freezeTable.allValues.copy;
        for (NSDictionary<NSString *, id> *entry in entries) {
            NSString *expression = entry[@"expression"];
            NSString *value = entry[@"value"];
            ZNMemoryValueType type = (ZNMemoryValueType)[entry[@"type"] integerValue];
            [strongSelf writeValue:value atExpression:expression type:type error:nil];
        }
    });
    dispatch_resume(_freezeTimer);
    return self;
}

- (NSNumber *)resolveAddressExpression:(NSString *)expression error:(NSString **)error {
    NSString *text = [ZNTrim(expression ?: @"") stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (text.length == 0) {
        if (error) *error = @"地址为空";
        return nil;
    }

    NSRange plus = [text rangeOfString:@"+"];
    if (plus.location != NSNotFound && plus.location > 0 && NSMaxRange(plus) < text.length) {
        NSString *module = [text substringToIndex:plus.location];
        NSString *offsetText = [text substringFromIndex:NSMaxRange(plus)];
        unsigned long long offset = 0;
        NSScanner *offsetScanner = [NSScanner scannerWithString:offsetText];
        BOOL offsetOK = NO;
        if ([offsetText.lowercaseString hasPrefix:@"0x"]) {
            offsetScanner.scanLocation = 2;
            offsetOK = [offsetScanner scanHexLongLong:&offset];
        } else {
            offsetOK = [offsetScanner scanUnsignedLongLong:&offset];
        }
        if (!offsetOK) {
            if (error) *error = @"模块偏移格式错误";
            return nil;
        }

        NSString *needle = module.lowercaseString;
        uint32_t count = _dyld_image_count();
        for (uint32_t i = 0; i < count; i++) {
            const char *cname = _dyld_get_image_name(i);
            const struct mach_header *header = _dyld_get_image_header(i);
            if (!header) continue;
            NSString *full = cname ? [NSString stringWithUTF8String:cname] : @"";
            NSString *leaf = full.lastPathComponent.lowercaseString;
            BOOL isMain = [needle isEqualToString:@"main"] && i == 0;
            BOOL matches = isMain || [leaf containsString:needle] || [full.lowercaseString containsString:needle];
            if (matches) {
                uintptr_t base = (uintptr_t)header;
                return @((unsigned long long)base + offset);
            }
        }
        if (error) *error = [NSString stringWithFormat:@"找不到模块：%@", module];
        return nil;
    }

    unsigned long long address = 0;
    NSScanner *scanner = [NSScanner scannerWithString:text];
    BOOL ok = NO;
    if ([text.lowercaseString hasPrefix:@"0x"]) {
        scanner.scanLocation = 2;
        ok = [scanner scanHexLongLong:&address];
    } else {
        ok = [scanner scanUnsignedLongLong:&address];
    }
    if (!ok || address == 0) {
        if (error) *error = @"地址格式错误，支持 0x1234 或 UnityFramework+0x1234";
        return nil;
    }
    return @(address);
}

- (BOOL)readBytesAtAddress:(vm_address_t)address buffer:(void *)buffer length:(vm_size_t)length error:(NSString **)error {
    vm_size_t outSize = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), address, length, (vm_address_t)(uintptr_t)buffer, &outSize);
    if (kr != KERN_SUCCESS || outSize != length) {
        if (error) *error = [NSString stringWithFormat:@"读取失败：%@", ZNKR(kr)];
        return NO;
    }
    return YES;
}

- (BOOL)writeBytes:(const void *)bytes length:(mach_msg_type_number_t)length address:(vm_address_t)address error:(NSString **)error {
    kern_return_t kr = vm_write(mach_task_self(), address, (vm_offset_t)(uintptr_t)bytes, length);
    if (kr != KERN_SUCCESS) {
        if (error) *error = [NSString stringWithFormat:@"写入失败：%@。当前页可能不可写。", ZNKR(kr)];
        return NO;
    }
    return YES;
}

- (NSData *)dataFromHexString:(NSString *)value error:(NSString **)error {
    NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@" <>,-_:\n\t"];
    NSString *clean = [[value componentsSeparatedByCharactersInSet:separators] componentsJoinedByString:@""];
    if ([clean.lowercaseString hasPrefix:@"0x"]) clean = [clean substringFromIndex:2];
    if (clean.length == 0 || (clean.length % 2) != 0) {
        if (error) *error = @"HEX 必须是偶数字节，例如 01FF90";
        return nil;
    }
    NSMutableData *data = [NSMutableData dataWithCapacity:clean.length / 2];
    for (NSUInteger i = 0; i < clean.length; i += 2) {
        NSString *pair = [clean substringWithRange:NSMakeRange(i, 2)];
        unsigned int byteValue = 0;
        NSScanner *scanner = [NSScanner scannerWithString:pair];
        if (![scanner scanHexInt:&byteValue]) {
            if (error) *error = @"HEX 包含非法字符";
            return nil;
        }
        uint8_t b = (uint8_t)byteValue;
        [data appendBytes:&b length:1];
    }
    return data;
}

- (NSString *)readValueAtExpression:(NSString *)expression type:(ZNMemoryValueType)type error:(NSString **)error {
    NSNumber *resolved = [self resolveAddressExpression:expression error:error];
    if (!resolved) return nil;
    vm_address_t address = (vm_address_t)resolved.unsignedLongLongValue;

    switch (type) {
        case ZNMemoryValueTypeInt32: {
            int32_t v = 0;
            if (![self readBytesAtAddress:address buffer:&v length:sizeof(v) error:error]) return nil;
            return [NSString stringWithFormat:@"%d", v];
        }
        case ZNMemoryValueTypeInt64: {
            int64_t v = 0;
            if (![self readBytesAtAddress:address buffer:&v length:sizeof(v) error:error]) return nil;
            return [NSString stringWithFormat:@"%lld", (long long)v];
        }
        case ZNMemoryValueTypeFloat32: {
            float v = 0;
            if (![self readBytesAtAddress:address buffer:&v length:sizeof(v) error:error]) return nil;
            return [NSString stringWithFormat:@"%.7g", v];
        }
        case ZNMemoryValueTypeFloat64: {
            double v = 0;
            if (![self readBytesAtAddress:address buffer:&v length:sizeof(v) error:error]) return nil;
            return [NSString stringWithFormat:@"%.12g", v];
        }
        case ZNMemoryValueTypeHexBytes: {
            uint8_t bytes[16] = {};
            if (![self readBytesAtAddress:address buffer:bytes length:sizeof(bytes) error:error]) return nil;
            NSMutableArray<NSString *> *parts = [NSMutableArray arrayWithCapacity:16];
            for (NSUInteger i = 0; i < 16; i++) [parts addObject:[NSString stringWithFormat:@"%02X", bytes[i]]];
            return [parts componentsJoinedByString:@" "];
        }
    }
}

- (BOOL)writeValue:(NSString *)value atExpression:(NSString *)expression type:(ZNMemoryValueType)type error:(NSString **)error {
    NSNumber *resolved = [self resolveAddressExpression:expression error:error];
    if (!resolved) return NO;
    vm_address_t address = (vm_address_t)resolved.unsignedLongLongValue;
    NSString *text = ZNTrim(value ?: @"");
    if (text.length == 0) {
        if (error) *error = @"值为空";
        return NO;
    }

    switch (type) {
        case ZNMemoryValueTypeInt32: {
            int32_t v = (int32_t)text.longLongValue;
            return [self writeBytes:&v length:(mach_msg_type_number_t)sizeof(v) address:address error:error];
        }
        case ZNMemoryValueTypeInt64: {
            int64_t v = (int64_t)text.longLongValue;
            return [self writeBytes:&v length:(mach_msg_type_number_t)sizeof(v) address:address error:error];
        }
        case ZNMemoryValueTypeFloat32: {
            float v = text.floatValue;
            return [self writeBytes:&v length:(mach_msg_type_number_t)sizeof(v) address:address error:error];
        }
        case ZNMemoryValueTypeFloat64: {
            double v = text.doubleValue;
            return [self writeBytes:&v length:(mach_msg_type_number_t)sizeof(v) address:address error:error];
        }
        case ZNMemoryValueTypeHexBytes: {
            NSData *data = [self dataFromHexString:text error:error];
            if (!data) return NO;
            return [self writeBytes:data.bytes length:(mach_msg_type_number_t)data.length address:address error:error];
        }
    }
}

- (BOOL)setFrozen:(BOOL)frozen expression:(NSString *)expression type:(ZNMemoryValueType)type value:(NSString *)value error:(NSString **)error {
    NSString *key = [ZNTrim(expression ?: @"") lowercaseString];
    if (key.length == 0) {
        if (error) *error = @"地址为空";
        return NO;
    }
    if (frozen) {
        if (![self writeValue:value atExpression:expression type:type error:error]) return NO;
        NSDictionary *entry = @{ @"expression": ZNTrim(expression), @"type": @(type), @"value": ZNTrim(value ?: @"") };
        dispatch_sync(self.freezeQueue, ^{ self.freezeTable[key] = entry; });
    } else {
        dispatch_sync(self.freezeQueue, ^{ [self.freezeTable removeObjectForKey:key]; });
    }
    return YES;
}

- (BOOL)isFrozenExpression:(NSString *)expression {
    __block BOOL frozen = NO;
    NSString *key = [ZNTrim(expression ?: @"") lowercaseString];
    dispatch_sync(self.freezeQueue, ^{ frozen = self.freezeTable[key] != nil; });
    return frozen;
}

- (NSArray<NSDictionary<NSString *,id> *> *)frozenEntries {
    __block NSArray *entries = nil;
    dispatch_sync(self.freezeQueue, ^{ entries = self.freezeTable.allValues.copy; });
    return entries ?: @[];
}

- (NSArray<NSDictionary<NSString *,id> *> *)loadedModules {
    NSMutableArray<NSDictionary<NSString *, id> *> *result = [NSMutableArray array];
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *cname = _dyld_get_image_name(i);
        const struct mach_header *header = _dyld_get_image_header(i);
        if (!header) continue;
        NSString *full = cname ? [NSString stringWithUTF8String:cname] : @"";
        NSString *name = full.lastPathComponent.length ? full.lastPathComponent : (i == 0 ? @"main" : @"unknown");
        uintptr_t base = (uintptr_t)header;
        intptr_t slide = _dyld_get_image_vmaddr_slide(i);
        [result addObject:@{ @"name": name,
                             @"path": full,
                             @"base": @((unsigned long long)base),
                             @"slide": @((long long)slide) }];
    }
    return result;
}

@end
