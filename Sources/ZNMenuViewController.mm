#import "ZNMenuViewController.h"
#import "ZNMemoryEngine.h"
#import <QuartzCore/QuartzCore.h>

NSNotificationName const ZNMenuValueChangedNotification = @"ZNMenuValueChangedNotification";

static UIColor *ZNColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

static UILabel *ZNLabel(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    return label;
}

@interface ZNNeonFrameView : UIView
@property (nonatomic, strong) CAGradientLayer *borderGradient;
@property (nonatomic, strong) CAShapeLayer *borderMask;
@end

@implementation ZNNeonFrameView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = ZNColor(0.018, 0.035, 0.075, 0.84);
    self.layer.cornerRadius = 16.0;
    self.layer.shadowColor = ZNColor(0.35, 0.05, 1.0, 1.0).CGColor;
    self.layer.shadowOpacity = 0.24;
    self.layer.shadowRadius = 13.0;
    self.layer.shadowOffset = CGSizeZero;

    _borderGradient = [CAGradientLayer layer];
    _borderGradient.startPoint = CGPointMake(0.0, 0.2);
    _borderGradient.endPoint = CGPointMake(1.0, 0.8);
    _borderGradient.colors = @[(id)ZNColor(0.0, 0.93, 1.0, 0.95).CGColor,
                               (id)ZNColor(0.38, 0.42, 1.0, 0.85).CGColor,
                               (id)ZNColor(0.96, 0.08, 0.95, 0.95).CGColor];
    _borderMask = [CAShapeLayer layer];
    _borderMask.fillColor = UIColor.clearColor.CGColor;
    _borderMask.strokeColor = UIColor.whiteColor.CGColor;
    _borderMask.lineWidth = 1.4;
    _borderGradient.mask = _borderMask;
    [self.layer addSublayer:_borderGradient];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.borderGradient.frame = self.bounds;
    CGRect pathBounds = CGRectInset(self.bounds, 0.8, 0.8);
    self.borderMask.path = [UIBezierPath bezierPathWithRoundedRect:pathBounds cornerRadius:15.2].CGPath;
}
@end

@interface ZNLogoView : UIView
@end

@implementation ZNLogoView
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, 4.0);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 7.0, ZNColor(0.0, 0.9, 1.0, 0.9).CGColor);
    CGContextSetStrokeColorWithColor(ctx, ZNColor(0.0, 0.92, 1.0, 1.0).CGColor);
    CGContextMoveToPoint(ctx, 9, 9);
    CGContextAddLineToPoint(ctx, CGRectGetWidth(rect) - 9, CGRectGetHeight(rect) - 9);
    CGContextStrokePath(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 7.0, ZNColor(0.95, 0.06, 0.95, 0.9).CGColor);
    CGContextSetStrokeColorWithColor(ctx, ZNColor(0.95, 0.12, 0.95, 1.0).CGColor);
    CGContextMoveToPoint(ctx, CGRectGetWidth(rect) - 9, 9);
    CGContextAddLineToPoint(ctx, 9, CGRectGetHeight(rect) - 9);
    CGContextStrokePath(ctx);
}
@end

@interface ZNNeonButton : UIButton
@property (nonatomic, assign) BOOL neonActive;
- (void)setNeonActive:(BOOL)active;
@end

@implementation ZNNeonButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.layer.cornerRadius = 9.0;
    self.layer.borderWidth = 1.0;
    self.titleLabel.font = [UIFont systemFontOfSize:10.5 weight:UIFontWeightSemibold];
    [self setNeonActive:NO];
    return self;
}

- (void)setNeonActive:(BOOL)active {
    _neonActive = active;
    self.backgroundColor = active ? ZNColor(0.0, 0.60, 0.74, 0.20) : ZNColor(0.04, 0.07, 0.14, 0.72);
    self.layer.borderColor = (active ? ZNColor(0.0, 0.92, 1.0, 0.95) : ZNColor(0.22, 0.42, 0.64, 0.55)).CGColor;
    self.layer.shadowColor = ZNColor(0.0, 0.92, 1.0, 1.0).CGColor;
    self.layer.shadowOpacity = active ? 0.38 : 0.0;
    self.layer.shadowRadius = active ? 7.0 : 0.0;
    [self setTitleColor:(active ? ZNColor(0.74, 0.98, 1.0, 1.0) : ZNColor(0.65, 0.73, 0.86, 1.0)) forState:UIControlStateNormal];
}
@end

@interface ZNMenuViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIVisualEffectView *blur;
@property (nonatomic, strong) UITextField *addressField;
@property (nonatomic, strong) UITextField *valueField;
@property (nonatomic, strong) UISegmentedControl *typeControl;
@property (nonatomic, strong) UILabel *resolvedLabel;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UITextView *inspectorView;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) ZNNeonButton *freezeButton;
@property (nonatomic, strong) NSArray<ZNNeonButton *> *navButtons;
@property (nonatomic, assign, getter=isMenuVisible) BOOL menuVisible;
@end

@implementation ZNMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    [self buildInterface];
    [self refreshModules];
    [self setMenuVisible:NO animated:NO];
}

- (UITextField *)fieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.backgroundColor = ZNColor(0.015, 0.028, 0.065, 0.94);
    field.textColor = UIColor.whiteColor;
    field.tintColor = ZNColor(0.0, 0.92, 1.0, 1.0);
    field.font = [UIFont monospacedSystemFontOfSize:12.0 weight:UIFontWeightMedium];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName: ZNColor(0.38, 0.48, 0.63, 1.0)}];
    field.layer.cornerRadius = 9.0;
    field.layer.borderWidth = 1.0;
    field.layer.borderColor = ZNColor(0.10, 0.48, 0.72, 0.55).CGColor;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.delegate = self;
    return field;
}

- (ZNNeonButton *)button:(NSString *)title selector:(SEL)selector {
    ZNNeonButton *button = [[ZNNeonButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)buildInterface {
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.layer.cornerRadius = 22.0;
    self.panel.layer.shadowColor = ZNColor(0.5, 0.02, 1.0, 1.0).CGColor;
    self.panel.layer.shadowOpacity = 0.34;
    self.panel.layer.shadowRadius = 22.0;
    self.panel.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:self.panel];

    self.blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blur.frame = self.panel.bounds;
    self.blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blur.layer.cornerRadius = 22.0;
    self.blur.clipsToBounds = YES;
    [self.panel addSubview:self.blur];

    UIView *content = self.blur.contentView;
    CAGradientLayer *wash = [CAGradientLayer layer];
    wash.name = @"ZNModifierWash";
    wash.startPoint = CGPointMake(0.0, 0.0);
    wash.endPoint = CGPointMake(1.0, 1.0);
    wash.colors = @[(id)ZNColor(0.0, 0.28, 0.45, 0.30).CGColor,
                    (id)ZNColor(0.05, 0.03, 0.17, 0.18).CGColor,
                    (id)ZNColor(0.48, 0.0, 0.58, 0.24).CGColor];
    [content.layer insertSublayer:wash atIndex:0];

    ZNLogoView *logo = [[ZNLogoView alloc] initWithFrame:CGRectZero];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.backgroundColor = UIColor.clearColor;
    UILabel *title = ZNLabel(@"NEON iOS MODIFIER", 16.0, UIFontWeightBold, UIColor.whiteColor);
    UILabel *subtitle = ZNLabel(@"RUNTIME MEMORY CONSOLE  ·  ARM64", 9.5, UIFontWeightMedium, ZNColor(0.49, 0.74, 0.90, 1.0));
    UILabel *tag = ZNLabel(@"SELF PROCESS", 9.0, UIFontWeightBold, ZNColor(0.0, 0.95, 1.0, 1.0));
    tag.textAlignment = NSTextAlignmentCenter;
    tag.backgroundColor = ZNColor(0.0, 0.55, 0.70, 0.15);
    tag.layer.cornerRadius = 8.0;
    tag.layer.borderWidth = 1.0;
    tag.layer.borderColor = ZNColor(0.0, 0.88, 1.0, 0.55).CGColor;
    tag.layer.masksToBounds = YES;
    [content addSubview:logo];
    [content addSubview:title];
    [content addSubview:subtitle];
    [content addSubview:tag];

    UIView *body = [[UIView alloc] initWithFrame:CGRectZero];
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:body];

    ZNNeonFrameView *nav = [[ZNNeonFrameView alloc] initWithFrame:CGRectZero];
    nav.translatesAutoresizingMaskIntoConstraints = NO;
    ZNNeonFrameView *editor = [[ZNNeonFrameView alloc] initWithFrame:CGRectZero];
    editor.translatesAutoresizingMaskIntoConstraints = NO;
    ZNNeonFrameView *inspector = [[ZNNeonFrameView alloc] initWithFrame:CGRectZero];
    inspector.translatesAutoresizingMaskIntoConstraints = NO;
    [body addSubview:nav];
    [body addSubview:editor];
    [body addSubview:inspector];

    UILabel *navTitle = ZNLabel(@"TOOLBOX", 10.0, UIFontWeightBold, ZNColor(0.54, 0.86, 1.0, 1.0));
    [nav addSubview:navTitle];
    NSArray<NSString *> *navTitles = @[@"MEMORY", @"MODULES", @"FREEZE", @"INFO"];
    NSMutableArray<ZNNeonButton *> *navButtons = [NSMutableArray array];
    for (NSInteger i = 0; i < navTitles.count; i++) {
        ZNNeonButton *b = [[ZNNeonButton alloc] initWithFrame:CGRectZero];
        b.tag = i;
        [b setTitle:navTitles[i] forState:UIControlStateNormal];
        [b addTarget:self action:@selector(navTapped:) forControlEvents:UIControlEventTouchUpInside];
        [b setNeonActive:(i == 0)];
        [nav addSubview:b];
        [navButtons addObject:b];
    }
    self.navButtons = navButtons.copy;
    UILabel *scope = ZNLabel(@"Injected dylib\ncurrent task only", 8.7, UIFontWeightRegular, ZNColor(0.42, 0.53, 0.69, 1.0));
    scope.numberOfLines = 2;
    [nav addSubview:scope];

    UILabel *editorTitle = ZNLabel(@"DIRECT ADDRESS EDITOR", 11.5, UIFontWeightSemibold, ZNColor(0.56, 0.90, 1.0, 1.0));
    UILabel *addressCaption = ZNLabel(@"ADDRESS / MODULE + RVA", 8.5, UIFontWeightMedium, ZNColor(0.48, 0.61, 0.78, 1.0));
    self.addressField = [self fieldWithPlaceholder:@"0x12345678  /  UnityFramework+0x1A2B3C"];
    UILabel *valueCaption = ZNLabel(@"VALUE", 8.5, UIFontWeightMedium, ZNColor(0.48, 0.61, 0.78, 1.0));
    self.valueField = [self fieldWithPlaceholder:@"123 / 1.5 / 01 FF 90 00"];
    self.typeControl = [[UISegmentedControl alloc] initWithItems:@[@"I32", @"I64", @"F32", @"F64", @"HEX"]];
    self.typeControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeControl.selectedSegmentIndex = 2;
    self.typeControl.selectedSegmentTintColor = ZNColor(0.0, 0.60, 0.72, 0.34);
    [self.typeControl setTitleTextAttributes:@{NSForegroundColorAttributeName: ZNColor(0.54, 0.64, 0.80, 1.0), NSFontAttributeName: [UIFont systemFontOfSize:9.5 weight:UIFontWeightSemibold]} forState:UIControlStateNormal];
    [self.typeControl setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor, NSFontAttributeName: [UIFont systemFontOfSize:9.5 weight:UIFontWeightBold]} forState:UIControlStateSelected];

    ZNNeonButton *readButton = [self button:@"READ" selector:@selector(readTapped)];
    ZNNeonButton *writeButton = [self button:@"WRITE" selector:@selector(writeTapped)];
    [writeButton setNeonActive:YES];
    self.freezeButton = [self button:@"FREEZE" selector:@selector(freezeTapped)];
    ZNNeonButton *clearButton = [self button:@"CLEAR" selector:@selector(clearTapped)];
    NSArray *editorViews = @[editorTitle, addressCaption, self.addressField, valueCaption, self.valueField, self.typeControl, readButton, writeButton, self.freezeButton, clearButton];
    for (UIView *v in editorViews) [editor addSubview:v];

    self.resolvedLabel = ZNLabel(@"Resolved: —", 9.0, UIFontWeightMedium, ZNColor(0.0, 0.84, 0.95, 1.0));
    self.resolvedLabel.font = [UIFont monospacedSystemFontOfSize:9.0 weight:UIFontWeightMedium];
    [editor addSubview:self.resolvedLabel];

    self.logView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logView.editable = NO;
    self.logView.selectable = YES;
    self.logView.backgroundColor = ZNColor(0.005, 0.015, 0.035, 0.72);
    self.logView.textColor = ZNColor(0.62, 0.82, 0.91, 1.0);
    self.logView.font = [UIFont monospacedSystemFontOfSize:9.0 weight:UIFontWeightRegular];
    self.logView.layer.cornerRadius = 8.0;
    self.logView.layer.borderWidth = 1.0;
    self.logView.layer.borderColor = ZNColor(0.07, 0.35, 0.52, 0.45).CGColor;
    self.logView.text = @"Ready. Enter an address or Module+RVA.";
    [editor addSubview:self.logView];

    UILabel *inspectorTitle = ZNLabel(@"RUNTIME INSPECTOR", 11.5, UIFontWeightSemibold, ZNColor(0.75, 0.63, 1.0, 1.0));
    UILabel *inspectorHint = ZNLabel(@"loaded images / bases / freeze state", 8.4, UIFontWeightMedium, ZNColor(0.50, 0.58, 0.73, 1.0));
    self.inspectorView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.inspectorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inspectorView.editable = NO;
    self.inspectorView.selectable = YES;
    self.inspectorView.backgroundColor = ZNColor(0.006, 0.014, 0.033, 0.68);
    self.inspectorView.textColor = ZNColor(0.70, 0.75, 0.91, 1.0);
    self.inspectorView.font = [UIFont monospacedSystemFontOfSize:8.7 weight:UIFontWeightRegular];
    self.inspectorView.layer.cornerRadius = 8.0;
    [inspector addSubview:inspectorTitle];
    [inspector addSubview:inspectorHint];
    [inspector addSubview:self.inspectorView];

    self.footerLabel = ZNLabel(@"NEON MODIFIER  ·  same-process memory editor  ·  iOS 13+ / arm64", 8.5, UIFontWeightMedium, ZNColor(0.37, 0.52, 0.68, 1.0));
    [content addSubview:self.footerLabel];

    [NSLayoutConstraint activateConstraints:@[
        [logo.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18],
        [logo.topAnchor constraintEqualToAnchor:content.topAnchor constant:10],
        [logo.widthAnchor constraintEqualToConstant:38],
        [logo.heightAnchor constraintEqualToConstant:38],
        [title.leadingAnchor constraintEqualToAnchor:logo.trailingAnchor constant:10],
        [title.topAnchor constraintEqualToAnchor:content.topAnchor constant:10],
        [subtitle.leadingAnchor constraintEqualToAnchor:title.leadingAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:2],
        [tag.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-18],
        [tag.centerYAnchor constraintEqualToAnchor:title.centerYAnchor constant:3],
        [tag.widthAnchor constraintEqualToConstant:94],
        [tag.heightAnchor constraintEqualToConstant:25],

        [body.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:12],
        [body.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-12],
        [body.topAnchor constraintEqualToAnchor:content.topAnchor constant:56],
        [body.bottomAnchor constraintEqualToAnchor:self.footerLabel.topAnchor constant:-6],

        [nav.leadingAnchor constraintEqualToAnchor:body.leadingAnchor],
        [nav.topAnchor constraintEqualToAnchor:body.topAnchor],
        [nav.bottomAnchor constraintEqualToAnchor:body.bottomAnchor],
        [nav.widthAnchor constraintEqualToConstant:106],
        [editor.leadingAnchor constraintEqualToAnchor:nav.trailingAnchor constant:8],
        [editor.topAnchor constraintEqualToAnchor:body.topAnchor],
        [editor.bottomAnchor constraintEqualToAnchor:body.bottomAnchor],
        [inspector.leadingAnchor constraintEqualToAnchor:editor.trailingAnchor constant:8],
        [inspector.trailingAnchor constraintEqualToAnchor:body.trailingAnchor],
        [inspector.topAnchor constraintEqualToAnchor:body.topAnchor],
        [inspector.bottomAnchor constraintEqualToAnchor:body.bottomAnchor],
        [editor.widthAnchor constraintEqualToAnchor:body.widthAnchor multiplier:0.54 constant:-57],
        [inspector.widthAnchor constraintGreaterThanOrEqualToConstant:190],

        [navTitle.leadingAnchor constraintEqualToAnchor:nav.leadingAnchor constant:11],
        [navTitle.topAnchor constraintEqualToAnchor:nav.topAnchor constant:11],
        [self.navButtons[0].leadingAnchor constraintEqualToAnchor:nav.leadingAnchor constant:8],
        [self.navButtons[0].trailingAnchor constraintEqualToAnchor:nav.trailingAnchor constant:-8],
        [self.navButtons[0].topAnchor constraintEqualToAnchor:navTitle.bottomAnchor constant:9],
        [self.navButtons[0].heightAnchor constraintEqualToConstant:36],
        [self.navButtons[1].leadingAnchor constraintEqualToAnchor:self.navButtons[0].leadingAnchor],
        [self.navButtons[1].trailingAnchor constraintEqualToAnchor:self.navButtons[0].trailingAnchor],
        [self.navButtons[1].topAnchor constraintEqualToAnchor:self.navButtons[0].bottomAnchor constant:6],
        [self.navButtons[1].heightAnchor constraintEqualToAnchor:self.navButtons[0].heightAnchor],
        [self.navButtons[2].leadingAnchor constraintEqualToAnchor:self.navButtons[0].leadingAnchor],
        [self.navButtons[2].trailingAnchor constraintEqualToAnchor:self.navButtons[0].trailingAnchor],
        [self.navButtons[2].topAnchor constraintEqualToAnchor:self.navButtons[1].bottomAnchor constant:6],
        [self.navButtons[2].heightAnchor constraintEqualToAnchor:self.navButtons[0].heightAnchor],
        [self.navButtons[3].leadingAnchor constraintEqualToAnchor:self.navButtons[0].leadingAnchor],
        [self.navButtons[3].trailingAnchor constraintEqualToAnchor:self.navButtons[0].trailingAnchor],
        [self.navButtons[3].topAnchor constraintEqualToAnchor:self.navButtons[2].bottomAnchor constant:6],
        [self.navButtons[3].heightAnchor constraintEqualToAnchor:self.navButtons[0].heightAnchor],
        [scope.leadingAnchor constraintEqualToAnchor:nav.leadingAnchor constant:11],
        [scope.trailingAnchor constraintEqualToAnchor:nav.trailingAnchor constant:-8],
        [scope.bottomAnchor constraintEqualToAnchor:nav.bottomAnchor constant:-9],

        [editorTitle.leadingAnchor constraintEqualToAnchor:editor.leadingAnchor constant:12],
        [editorTitle.topAnchor constraintEqualToAnchor:editor.topAnchor constant:10],
        [addressCaption.leadingAnchor constraintEqualToAnchor:editorTitle.leadingAnchor],
        [addressCaption.topAnchor constraintEqualToAnchor:editorTitle.bottomAnchor constant:7],
        [self.addressField.leadingAnchor constraintEqualToAnchor:editor.leadingAnchor constant:11],
        [self.addressField.trailingAnchor constraintEqualToAnchor:editor.trailingAnchor constant:-11],
        [self.addressField.topAnchor constraintEqualToAnchor:addressCaption.bottomAnchor constant:3],
        [self.addressField.heightAnchor constraintEqualToConstant:32],
        [valueCaption.leadingAnchor constraintEqualToAnchor:editorTitle.leadingAnchor],
        [valueCaption.topAnchor constraintEqualToAnchor:self.addressField.bottomAnchor constant:6],
        [self.valueField.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor],
        [self.valueField.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor],
        [self.valueField.topAnchor constraintEqualToAnchor:valueCaption.bottomAnchor constant:3],
        [self.valueField.heightAnchor constraintEqualToConstant:32],
        [self.typeControl.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor],
        [self.typeControl.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor],
        [self.typeControl.topAnchor constraintEqualToAnchor:self.valueField.bottomAnchor constant:7],
        [self.typeControl.heightAnchor constraintEqualToConstant:29],
        [readButton.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor],
        [readButton.topAnchor constraintEqualToAnchor:self.typeControl.bottomAnchor constant:7],
        [readButton.heightAnchor constraintEqualToConstant:34],
        [writeButton.leadingAnchor constraintEqualToAnchor:readButton.trailingAnchor constant:6],
        [writeButton.topAnchor constraintEqualToAnchor:readButton.topAnchor],
        [writeButton.heightAnchor constraintEqualToAnchor:readButton.heightAnchor],
        [self.freezeButton.leadingAnchor constraintEqualToAnchor:writeButton.trailingAnchor constant:6],
        [self.freezeButton.topAnchor constraintEqualToAnchor:readButton.topAnchor],
        [self.freezeButton.heightAnchor constraintEqualToAnchor:readButton.heightAnchor],
        [clearButton.leadingAnchor constraintEqualToAnchor:self.freezeButton.trailingAnchor constant:6],
        [clearButton.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor],
        [clearButton.topAnchor constraintEqualToAnchor:readButton.topAnchor],
        [clearButton.heightAnchor constraintEqualToAnchor:readButton.heightAnchor],
        [writeButton.widthAnchor constraintEqualToAnchor:readButton.widthAnchor],
        [self.freezeButton.widthAnchor constraintEqualToAnchor:readButton.widthAnchor],
        [clearButton.widthAnchor constraintEqualToAnchor:readButton.widthAnchor],
        [self.resolvedLabel.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor],
        [self.resolvedLabel.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor],
        [self.resolvedLabel.topAnchor constraintEqualToAnchor:readButton.bottomAnchor constant:5],
        [self.logView.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor],
        [self.logView.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor],
        [self.logView.topAnchor constraintEqualToAnchor:self.resolvedLabel.bottomAnchor constant:4],
        [self.logView.bottomAnchor constraintEqualToAnchor:editor.bottomAnchor constant:-9],

        [inspectorTitle.leadingAnchor constraintEqualToAnchor:inspector.leadingAnchor constant:11],
        [inspectorTitle.topAnchor constraintEqualToAnchor:inspector.topAnchor constant:10],
        [inspectorHint.leadingAnchor constraintEqualToAnchor:inspectorTitle.leadingAnchor],
        [inspectorHint.topAnchor constraintEqualToAnchor:inspectorTitle.bottomAnchor constant:2],
        [self.inspectorView.leadingAnchor constraintEqualToAnchor:inspector.leadingAnchor constant:9],
        [self.inspectorView.trailingAnchor constraintEqualToAnchor:inspector.trailingAnchor constant:-9],
        [self.inspectorView.topAnchor constraintEqualToAnchor:inspectorHint.bottomAnchor constant:7],
        [self.inspectorView.bottomAnchor constraintEqualToAnchor:inspector.bottomAnchor constant:-9],

        [self.footerLabel.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18],
        [self.footerLabel.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-7],
        [self.footerLabel.heightAnchor constraintEqualToConstant:16]
    ]];
}

- (ZNMemoryValueType)selectedType {
    NSInteger index = self.typeControl.selectedSegmentIndex;
    if (index < 0 || index > ZNMemoryValueTypeHexBytes) return ZNMemoryValueTypeFloat32;
    return (ZNMemoryValueType)index;
}

- (void)appendLog:(NSString *)line {
    NSString *current = self.logView.text ?: @"";
    NSString *next = current.length ? [current stringByAppendingFormat:@"\n%@", line] : line;
    NSArray<NSString *> *lines = [next componentsSeparatedByString:@"\n"];
    if (lines.count > 7) {
        lines = [lines subarrayWithRange:NSMakeRange(lines.count - 7, 7)];
        next = [lines componentsJoinedByString:@"\n"];
    }
    self.logView.text = next;
    if (self.logView.text.length) [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length - 1, 1)];
}

- (void)updateResolvedAddress {
    NSString *error = nil;
    NSNumber *address = [[ZNMemoryEngine shared] resolveAddressExpression:self.addressField.text ?: @"" error:&error];
    if (address) {
        self.resolvedLabel.text = [NSString stringWithFormat:@"Resolved: 0x%llX", address.unsignedLongLongValue];
        self.resolvedLabel.textColor = ZNColor(0.0, 0.90, 1.0, 1.0);
    } else {
        self.resolvedLabel.text = [NSString stringWithFormat:@"Resolved: %@", error ?: @"—"];
        self.resolvedLabel.textColor = ZNColor(1.0, 0.36, 0.62, 1.0);
    }
    BOOL frozen = [[ZNMemoryEngine shared] isFrozenExpression:self.addressField.text ?: @""];
    [self.freezeButton setTitle:(frozen ? @"UNFREEZE" : @"FREEZE") forState:UIControlStateNormal];
    [self.freezeButton setNeonActive:frozen];
}

- (void)readTapped {
    [self.view endEditing:YES];
    NSString *error = nil;
    NSString *value = [[ZNMemoryEngine shared] readValueAtExpression:self.addressField.text ?: @"" type:self.selectedType error:&error];
    if (value) {
        self.valueField.text = value;
        [self appendLog:[NSString stringWithFormat:@"READ  %@  => %@", self.addressField.text ?: @"", value]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key": @"memory_read", @"value": value}];
    } else {
        [self appendLog:[NSString stringWithFormat:@"ERR   %@", error ?: @"read failed"]];
    }
    [self updateResolvedAddress];
}

- (void)writeTapped {
    [self.view endEditing:YES];
    NSString *error = nil;
    BOOL ok = [[ZNMemoryEngine shared] writeValue:self.valueField.text ?: @"" atExpression:self.addressField.text ?: @"" type:self.selectedType error:&error];
    if (ok) {
        [self appendLog:[NSString stringWithFormat:@"WRITE %@  <= %@", self.addressField.text ?: @"", self.valueField.text ?: @""]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key": @"memory_write", @"value": self.valueField.text ?: @""}];
    } else {
        [self appendLog:[NSString stringWithFormat:@"ERR   %@", error ?: @"write failed"]];
    }
    [self updateResolvedAddress];
}

- (void)freezeTapped {
    [self.view endEditing:YES];
    NSString *expression = self.addressField.text ?: @"";
    BOOL currentlyFrozen = [[ZNMemoryEngine shared] isFrozenExpression:expression];
    NSString *error = nil;
    BOOL ok = [[ZNMemoryEngine shared] setFrozen:!currentlyFrozen expression:expression type:self.selectedType value:self.valueField.text ?: @"" error:&error];
    if (ok) {
        [self appendLog:[NSString stringWithFormat:@"%@ %@", currentlyFrozen ? @"UNFREEZE" : @"FREEZE", expression]];
        [self refreshFreezeState];
    } else {
        [self appendLog:[NSString stringWithFormat:@"ERR   %@", error ?: @"freeze failed"]];
    }
    [self updateResolvedAddress];
}

- (void)clearTapped {
    self.addressField.text = @"";
    self.valueField.text = @"";
    self.resolvedLabel.text = @"Resolved: —";
    self.logView.text = @"Ready. Enter an address or Module+RVA.";
    [self.freezeButton setTitle:@"FREEZE" forState:UIControlStateNormal];
    [self.freezeButton setNeonActive:NO];
    [self.view endEditing:YES];
}

- (void)refreshModules {
    NSArray<NSDictionary<NSString *, id> *> *modules = [[ZNMemoryEngine shared] loadedModules];
    NSMutableString *text = [NSMutableString string];
    NSUInteger shown = MIN((NSUInteger)18, modules.count);
    for (NSUInteger i = 0; i < shown; i++) {
        NSDictionary *module = modules[i];
        [text appendFormat:@"%@\n0x%llX\n\n", module[@"name"], [module[@"base"] unsignedLongLongValue]];
    }
    if (modules.count > shown) [text appendFormat:@"… %lu more images", (unsigned long)(modules.count - shown)];
    self.inspectorView.text = text.length ? text : @"No dyld images found.";
}

- (void)refreshFreezeState {
    NSArray<NSDictionary<NSString *, id> *> *entries = [[ZNMemoryEngine shared] frozenEntries];
    if (entries.count == 0) {
        self.inspectorView.text = @"No frozen values.\n\nFreeze writes the selected value back to the same address about every 150 ms.";
        return;
    }
    NSMutableString *text = [NSMutableString stringWithFormat:@"Frozen: %lu\n\n", (unsigned long)entries.count];
    for (NSDictionary *entry in entries) {
        [text appendFormat:@"%@\n= %@\n\n", entry[@"expression"], entry[@"value"]];
    }
    self.inspectorView.text = text;
}

- (void)navTapped:(ZNNeonButton *)sender {
    for (ZNNeonButton *button in self.navButtons) [button setNeonActive:(button == sender)];
    switch (sender.tag) {
        case 0:
            self.inspectorView.text = @"MEMORY MODE\n\nUse an absolute address or Module+RVA. READ reads current memory. WRITE changes the current process. HEX reads 16 bytes; writes exactly the bytes entered.";
            break;
        case 1:
            [self refreshModules];
            break;
        case 2:
            [self refreshFreezeState];
            break;
        default:
            self.inspectorView.text = @"NEON iOS MODIFIER\n\nNative UIKit + Mach VM.\narm64 / iOS 13+\n\nScope: the process that loaded this dylib.\nAddress syntax:\n  0x12345678\n  main+0x1234\n  UnityFramework+0x1234";
            break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.addressField) [self updateResolvedAddress];
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat availableWidth = CGRectGetWidth(bounds) - safe.left - safe.right;
    CGFloat availableHeight = CGRectGetHeight(bounds) - safe.top - safe.bottom;
    CGFloat width = MIN(940.0, MAX(650.0, availableWidth - 16.0));
    CGFloat height = MIN(460.0, MAX(350.0, availableHeight - 8.0));
    width = MIN(width, availableWidth - 6.0);
    height = MIN(height, availableHeight - 4.0);
    self.panel.frame = CGRectIntegral(CGRectMake(safe.left + (availableWidth - width) * 0.5,
                                                 safe.top + (availableHeight - height) * 0.5,
                                                 width,
                                                 height));
    self.blur.frame = self.panel.bounds;
    for (CALayer *layer in self.blur.contentView.layer.sublayers) {
        if ([layer.name isEqualToString:@"ZNModifierWash"]) layer.frame = self.blur.contentView.bounds;
    }
}

- (void)toggleMenu {
    [self setMenuVisible:!self.menuVisible animated:YES];
}

- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated {
    self.menuVisible = visible;
    void (^changes)(void) = ^{
        self.panel.alpha = visible ? 1.0 : 0.0;
        self.panel.transform = visible ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.965, 0.965);
    };
    if (!animated) {
        changes();
        self.panel.hidden = !visible;
        return;
    }
    if (visible) {
        self.panel.hidden = NO;
        [self refreshModules];
    }
    [UIView animateWithDuration:0.20
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:changes
                     completion:^(__unused BOOL finished) { if (!visible) self.panel.hidden = YES; }];
}

@end
