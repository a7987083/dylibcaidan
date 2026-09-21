#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZNSatellaStartResult) {
    ZNSatellaStartResultStarted = 0,
    ZNSatellaStartResultAlreadyStarted,
    ZNSatellaStartResultTargetNotFound,
    ZNSatellaStartResultTargetBuildMismatch,
    ZNSatellaStartResultLoadFailed,
};

FOUNDATION_EXPORT ZNSatellaStartResult ZNSatellaPassiveStart(void);
FOUNDATION_EXPORT NSString *ZNSatellaStartResultString(ZNSatellaStartResult result);

NS_ASSUME_NONNULL_END
