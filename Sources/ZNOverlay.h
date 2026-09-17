#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZNOverlayWindow : UIWindow
@end

@interface ZNFloatingButton : UIControl
@property (nonatomic, copy, nullable) void (^tapHandler)(void);
@end

@interface ZNOverlayManager : NSObject
+ (instancetype)shared;
- (void)start;
@end

NS_ASSUME_NONNULL_END
