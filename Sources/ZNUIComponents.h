#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
UIColor *ZNColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a);
UILabel *ZNLabel(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color);
UIImage * _Nullable ZNSymbol(NSString *name, CGFloat size);
@interface ZNGlowPanel : UIView @end
@interface ZNNeonSwitch : UIControl
@property(nonatomic,assign,getter=isOn) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end
@interface ZNControlRow : UIView
@property(nonatomic,strong,readonly) ZNNeonSwitch *neonSwitch;
- (instancetype)initWithTitle:(NSString*)title symbol:(NSString*)symbol on:(BOOL)on;
@end
@interface ZNSliderRow : UIView
@property(nonatomic,strong,readonly) UILabel *valueLabel;
@property(nonatomic,strong,readonly) UISlider *slider;
- (instancetype)initWithTitle:(NSString*)title symbol:(NSString*)symbol value:(float)value valueText:(NSString*)valueText tint:(UIColor*)tint;
@end
@interface ZNPresetCell : UICollectionViewCell
@property(nonatomic,strong,readonly) UIImageView *imageView;
@property(nonatomic,strong,readonly) UILabel *caption;
@end
NS_ASSUME_NONNULL_END
