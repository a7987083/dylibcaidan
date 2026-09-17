#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const ZNMenuValueChangedNotification;

@interface ZNMenuViewController : UIViewController
@property (nonatomic, readonly, getter=isMenuVisible) BOOL menuVisible;
- (void)toggleMenu;
- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated;
@end

NS_ASSUME_NONNULL_END
