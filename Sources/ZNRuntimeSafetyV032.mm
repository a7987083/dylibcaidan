#import "ZNRuntimeSafetyV032.h"
#import "ZNMemoryEngine.h"
#import <objc/runtime.h>
#import <errno.h>
#import <math.h>
#import <limits.h>

__attribute__((used)) static const char kZNRuntimeSafetyMarker[] = "ZN_RUNTIME_SAFETY_V032";

static NSNumber *(*ZNOriginalResolve)(id, SEL, NSString *, NSString **) = nullptr;
static BOOL (*ZNOriginalWriteValue)(id, SEL, NSString *, NSString *, ZNMemoryValueType, NSString **) = nullptr;
static BOOL (*ZNOriginalSetFrozen)(id, SEL, BOOL, NSString *, ZNMemoryValueType, NSString *, NSString **) = nullptr;
static BOOL (*ZNOriginalIsFrozen)(id, SEL, NSString *) = nullptr;

static NSString *ZNTrimSafety(NSString *s) {
    return [s ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static BOOL ZNStrictUnsigned(NSString *text, unsigned long long *outValue) {
    NSString *s = ZNTrimSafety(text);
    if (!s.length) return NO;
    int base = 10;
    const char *p = s.UTF8String;
    if ([s.lowercaseString hasPrefix:@"0x"]) {
        if (s.length <= 2) return NO;
        base = 16;
        p += 2;
    }
    errno = 0;
    char *end = nullptr;
    unsigned long long value = strtoull(p, &end, base);
    if (errno == ERANGE || !end || *end != '\0') return NO;
    if (outValue) *outValue = value;
    return YES;
}

static BOOL ZNValidateAddressExpression(NSString *expression, NSString **error) {
    NSString *s = [[ZNTrimSafety(expression) stringByReplacingOccurrencesOfString:@" " withString:@""] copy];
    if (!s.length) { if (error) *error = @"地址为空"; return NO; }
    NSArray<NSString *> *parts = [s componentsSeparatedByString:@"+"];
    if (parts.count == 1) {
        unsigned long long v = 0;
        if (!ZNStrictUnsigned(parts[0], &v) || v == 0) { if (error) *error = @"地址格式错误"; return NO; }
        return YES;
    }
    if (parts.count != 2 || !parts[0].length || !parts[1].length) { if (error) *error = @"模块+RVA 格式错误"; return NO; }
    unsigned long long offset = 0;
    if (!ZNStrictUnsigned(parts[1], &offset)) { if (error) *error = @"模块偏移格式错误"; return NO; }
    return YES;
}

static BOOL ZNStrictSignedInteger(NSString *text, long long minValue, unsigned long long maxAbs, long long *outValue) {
    NSString *s = ZNTrimSafety(text);
    if (!s.length) return NO;
    errno = 0;
    char *end = nullptr;
    long long value = strtoll(s.UTF8String, &end, 10);
    if (errno == ERANGE || !end || *end != '\0') return NO;
    if (value < minValue) return NO;
    if (value >= 0 && (unsigned long long)value > maxAbs) return NO;
    if (outValue) *outValue = value;
    return YES;
}

static BOOL ZNStrictFloat(NSString *text) {
    NSString *s = ZNTrimSafety(text);
    if (!s.length) return NO;
    errno = 0;
    char *end = nullptr;
    double value = strtod(s.UTF8String, &end);
    if (errno == ERANGE || !end || *end != '\0' || !isfinite(value)) return NO;
    return YES;
}

static BOOL ZNValidateValue(NSString *value, ZNMemoryValueType type, NSString **error) {
    NSString *s = ZNTrimSafety(value);
    switch (type) {
        case ZNMemoryValueTypeInt32: {
            long long v = 0;
            if (!ZNStrictSignedInteger(s, INT32_MIN, INT32_MAX, &v)) { if (error) *error = @"I32 数值格式或范围错误"; return NO; }
            return YES;
        }
        case ZNMemoryValueTypeInt64: {
            if (!s.length) { if (error) *error = @"I64 数值为空"; return NO; }
            errno = 0; char *end = nullptr; (void)strtoll(s.UTF8String, &end, 10);
            if (errno == ERANGE || !end || *end != '\0') { if (error) *error = @"I64 数值格式或范围错误"; return NO; }
            return YES;
        }
        case ZNMemoryValueTypeFloat32:
        case ZNMemoryValueTypeFloat64:
            if (!ZNStrictFloat(s)) { if (error) *error = @"浮点数格式错误，且不允许 NaN/Inf"; return NO; }
            return YES;
        case ZNMemoryValueTypeHexBytes: {
            NSCharacterSet *sep = [NSCharacterSet characterSetWithCharactersInString:@" <>,-_:\n\t"];
            NSString *clean = [[s componentsSeparatedByCharactersInSet:sep] componentsJoinedByString:@""];
            if ([clean.lowercaseString hasPrefix:@"0x"]) clean = [clean substringFromIndex:2];
            if (!clean.length || (clean.length % 2) != 0) { if (error) *error = @"HEX 必须是偶数字节"; return NO; }
            NSCharacterSet *hex = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"];
            if ([[clean stringByTrimmingCharactersInSet:hex] length] != 0) { if (error) *error = @"HEX 包含非法字符"; return NO; }
            return YES;
        }
    }
    return NO;
}

static NSString *ZNCanonicalExpression(id self, NSString *expression) {
    NSString *localError = nil;
    NSNumber *resolved = ZNOriginalResolve ? ZNOriginalResolve(self, @selector(resolveAddressExpression:error:), expression, &localError) : nil;
    if (!resolved) return ZNTrimSafety(expression);
    return [NSString stringWithFormat:@"0x%llX", resolved.unsignedLongLongValue];
}

static NSNumber *ZNPatchedResolve(id self, SEL _cmd, NSString *expression, NSString **error) {
    if (!ZNValidateAddressExpression(expression, error)) return nil;
    return ZNOriginalResolve ? ZNOriginalResolve(self, _cmd, expression, error) : nil;
}

static BOOL ZNPatchedWriteValue(id self, SEL _cmd, NSString *value, NSString *expression, ZNMemoryValueType type, NSString **error) {
    if (!ZNValidateAddressExpression(expression, error)) return NO;
    if (!ZNValidateValue(value, type, error)) return NO;
    return ZNOriginalWriteValue ? ZNOriginalWriteValue(self, _cmd, value, expression, type, error) : NO;
}

static BOOL ZNPatchedSetFrozen(id self, SEL _cmd, BOOL frozen, NSString *expression, ZNMemoryValueType type, NSString *value, NSString **error) {
    if (!ZNValidateAddressExpression(expression, error)) return NO;
    if (frozen && !ZNValidateValue(value, type, error)) return NO;
    NSString *canonical = ZNCanonicalExpression(self, expression);
    return ZNOriginalSetFrozen ? ZNOriginalSetFrozen(self, _cmd, frozen, canonical, type, value, error) : NO;
}

static BOOL ZNPatchedIsFrozen(id self, SEL _cmd, NSString *expression) {
    if (!expression.length) return NO;
    NSString *canonical = ZNCanonicalExpression(self, expression);
    return ZNOriginalIsFrozen ? ZNOriginalIsFrozen(self, _cmd, canonical) : NO;
}

static BOOL ZNSwizzleSafety(Class cls, SEL selector, IMP replacement, IMP *originalOut) {
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return NO;
    *originalOut = method_getImplementation(method);
    method_setImplementation(method, replacement);
    return YES;
}

void ZNInstallRuntimeSafetyV032(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"ZNMemoryEngine");
        if (!cls) return;
        ZNSwizzleSafety(cls, @selector(resolveAddressExpression:error:), (IMP)ZNPatchedResolve, (IMP *)&ZNOriginalResolve);
        ZNSwizzleSafety(cls, @selector(writeValue:atExpression:type:error:), (IMP)ZNPatchedWriteValue, (IMP *)&ZNOriginalWriteValue);
        ZNSwizzleSafety(cls, @selector(setFrozen:expression:type:value:error:), (IMP)ZNPatchedSetFrozen, (IMP *)&ZNOriginalSetFrozen);
        ZNSwizzleSafety(cls, @selector(isFrozenExpression:), (IMP)ZNPatchedIsFrozen, (IMP *)&ZNOriginalIsFrozen);
    });
}
