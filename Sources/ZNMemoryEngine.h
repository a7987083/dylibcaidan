#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZNMemoryValueType) {
    ZNMemoryValueTypeInt32 = 0,
    ZNMemoryValueTypeInt64,
    ZNMemoryValueTypeFloat32,
    ZNMemoryValueTypeFloat64,
    ZNMemoryValueTypeHexBytes,
};

@interface ZNMemoryEngine : NSObject
+ (instancetype)shared;
- (nullable NSNumber *)resolveAddressExpression:(NSString *)expression error:(NSString * _Nullable * _Nullable)error;
- (nullable NSString *)readValueAtExpression:(NSString *)expression type:(ZNMemoryValueType)type error:(NSString * _Nullable * _Nullable)error;
- (BOOL)writeValue:(NSString *)value atExpression:(NSString *)expression type:(ZNMemoryValueType)type error:(NSString * _Nullable * _Nullable)error;
- (BOOL)setFrozen:(BOOL)frozen expression:(NSString *)expression type:(ZNMemoryValueType)type value:(NSString *)value error:(NSString * _Nullable * _Nullable)error;
- (BOOL)isFrozenExpression:(NSString *)expression;
- (NSArray<NSDictionary<NSString *, id> *> *)frozenEntries;
- (NSArray<NSDictionary<NSString *, id> *> *)loadedModules;
@end

NS_ASSUME_NONNULL_END
