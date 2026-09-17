#import "ZNMenuViewController.h"
#import "ZNMemoryEngine.h"
#import "ZNThemeCatalog.h"
#import <QuartzCore/QuartzCore.h>

NSNotificationName const ZNMenuValueChangedNotification = @"ZNMenuValueChangedNotification";

static UIColor *C(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

static UILabel *L(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color) {
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
@property (nonatomic, assign) CGFloat themeCorner;
- (void)applyTheme:(NSDictionary<NSString *, id> *)theme;
@end

@implementation ZNNeonFrameView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    _themeCorner = 16.0;
    self.layer.shadowOffset = CGSizeZero;
    _borderGradient = [CAGradientLayer layer];
    _borderGradient.startPoint = CGPointMake(0.0, 0.15);
    _borderGradient.endPoint = CGPointMake(1.0, 0.85);
    _borderMask = [CAShapeLayer layer];
    _borderMask.fillColor = UIColor.clearColor.CGColor;
    _borderMask.strokeColor = UIColor.whiteColor.CGColor;
    _borderGradient.mask = _borderMask;
    [self.layer addSublayer:_borderGradient];
    return self;
}
- (void)applyTheme:(NSDictionary<NSString *, id> *)theme {
    UIColor *primary = theme[ZNThemePrimaryKey];
    UIColor *secondary = theme[ZNThemeSecondaryKey];
    self.backgroundColor = theme[ZNThemeSurfaceKey];
    self.themeCorner = [theme[ZNThemeCornerKey] doubleValue];
    self.layer.cornerRadius = self.themeCorner;
    self.layer.shadowColor = secondary.CGColor;
    self.layer.shadowOpacity = [theme[ZNThemeShadowKey] doubleValue] * 0.55;
    self.layer.shadowRadius = 12.0;
    self.borderGradient.colors = @[(id)primary.CGColor, (id)secondary.CGColor];
    self.borderMask.lineWidth = [theme[ZNThemeBorderKey] doubleValue];
    [self setNeedsLayout];
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.borderGradient.frame = self.bounds;
    CGRect rect = CGRectInset(self.bounds, 0.8, 0.8);
    self.borderMask.path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:MAX(1.0, self.themeCorner - 0.8)].CGPath;
}
@end

@interface ZNLogoView : UIView
@property (nonatomic, strong) UIColor *primary;
@property (nonatomic, strong) UIColor *secondary;
- (void)applyTheme:(NSDictionary<NSString *, id> *)theme;
@end

@implementation ZNLogoView
- (void)applyTheme:(NSDictionary<NSString *, id> *)theme {
    self.primary = theme[ZNThemePrimaryKey];
    self.secondary = theme[ZNThemeSecondaryKey];
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    UIColor *p = self.primary ?: UIColor.cyanColor;
    UIColor *s = self.secondary ?: UIColor.magentaColor;
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, 4.0);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 7.0, p.CGColor);
    CGContextSetStrokeColorWithColor(ctx, p.CGColor);
    CGContextMoveToPoint(ctx, 9, 9);
    CGContextAddLineToPoint(ctx, CGRectGetWidth(rect)-9, CGRectGetHeight(rect)-9);
    CGContextStrokePath(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 7.0, s.CGColor);
    CGContextSetStrokeColorWithColor(ctx, s.CGColor);
    CGContextMoveToPoint(ctx, CGRectGetWidth(rect)-9, 9);
    CGContextAddLineToPoint(ctx, 9, CGRectGetHeight(rect)-9);
    CGContextStrokePath(ctx);
}
@end

@interface ZNNeonButton : UIButton
@property (nonatomic, assign) BOOL neonActive;
@property (nonatomic, strong) UIColor *themePrimary;
@property (nonatomic, strong) UIColor *themeSecondary;
@property (nonatomic, strong) UIColor *themeSurface;
@property (nonatomic, strong) UIColor *themeText;
@property (nonatomic, strong) UIColor *themeMuted;
@property (nonatomic, assign) CGFloat themeCorner;
- (void)applyTheme:(NSDictionary<NSString *, id> *)theme;
- (void)setNeonActive:(BOOL)active;
@end

@implementation ZNNeonButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.layer.borderWidth = 1.0;
    self.layer.shadowOffset = CGSizeZero;
    self.titleLabel.font = [UIFont systemFontOfSize:10.5 weight:UIFontWeightSemibold];
    return self;
}
- (void)applyTheme:(NSDictionary<NSString *, id> *)theme {
    self.themePrimary = theme[ZNThemePrimaryKey];
    self.themeSecondary = theme[ZNThemeSecondaryKey];
    self.themeSurface = theme[ZNThemeSurfaceAltKey];
    self.themeText = theme[ZNThemeTextKey];
    self.themeMuted = theme[ZNThemeMutedKey];
    self.themeCorner = MAX(4.0, [theme[ZNThemeCornerKey] doubleValue] * 0.58);
    self.layer.cornerRadius = self.themeCorner;
    [self setNeonActive:self.neonActive];
}
- (void)setNeonActive:(BOOL)active {
    _neonActive = active;
    UIColor *p = self.themePrimary ?: C(0,0.9,1,1);
    UIColor *s = self.themeSecondary ?: C(0.9,0.1,1,1);
    UIColor *surface = self.themeSurface ?: C(0.03,0.05,0.12,0.85);
    UIColor *text = self.themeText ?: UIColor.whiteColor;
    UIColor *muted = self.themeMuted ?: C(0.6,0.7,0.8,1);
    self.backgroundColor = active ? [p colorWithAlphaComponent:0.16] : surface;
    self.layer.borderColor = (active ? p : [p colorWithAlphaComponent:0.38]).CGColor;
    self.layer.shadowColor = (active ? s : p).CGColor;
    self.layer.shadowOpacity = active ? 0.52 : 0.0;
    self.layer.shadowRadius = active ? 7.0 : 0.0;
    [self setTitleColor:(active ? text : muted) forState:UIControlStateNormal];
}
@end

@interface ZNMenuViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIVisualEffectView *blur;
@property (nonatomic, strong) CAGradientLayer *washLayer;
@property (nonatomic, strong) ZNLogoView *logoView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *statusTag;
@property (nonatomic, strong) UITextField *addressField;
@property (nonatomic, strong) UITextField *valueField;
@property (nonatomic, strong) UISegmentedControl *typeControl;
@property (nonatomic, strong) UILabel *resolvedLabel;
@property (nonatomic, strong) UITextView *logView;
@property (nonatomic, strong) UITextView *inspectorView;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) ZNNeonButton *freezeButton;
@property (nonatomic, strong) ZNNeonButton *styleButton;
@property (nonatomic, strong) NSArray<ZNNeonButton *> *navButtons;
@property (nonatomic, strong) NSMutableArray<ZNNeonButton *> *themedButtons;
@property (nonatomic, strong) NSMutableArray<ZNNeonFrameView *> *themedFrames;
@property (nonatomic, strong) NSMutableArray<UILabel *> *accentLabels;
@property (nonatomic, strong) ZNNeonFrameView *stylePanel;
@property (nonatomic, strong) UILabel *stylePanelTitle;
@property (nonatomic, strong) UILabel *stylePanelHint;
@property (nonatomic, strong) NSArray<ZNNeonButton *> *themeChoiceButtons;
@property (nonatomic, assign) NSInteger selectedThemeIndex;
@property (nonatomic, assign, getter=isMenuVisible) BOOL menuVisible;
@end

@implementation ZNMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.themedButtons = [NSMutableArray array];
    self.themedFrames = [NSMutableArray array];
    self.accentLabels = [NSMutableArray array];
    NSInteger saved = [[NSUserDefaults standardUserDefaults] integerForKey:@"ZNNeonModifierThemeIndex"];
    self.selectedThemeIndex = (saved >= 0 && saved < (NSInteger)ZNThemeCatalog().count) ? saved : 0;
    [self buildInterface];
    [self applyThemeAtIndex:self.selectedThemeIndex persist:NO];
    [self refreshModules];
    [self setMenuVisible:NO animated:NO];
}

- (UITextField *)fieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.translatesAutoresizingMaskIntoConstraints = NO;
    field.font = [UIFont monospacedSystemFontOfSize:12.0 weight:UIFontWeightMedium];
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,10,1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.delegate = self;
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName:C(0.38,0.48,0.63,1)}];
    field.layer.borderWidth = 1.0;
    return field;
}

- (ZNNeonButton *)button:(NSString *)title selector:(SEL)selector {
    ZNNeonButton *button = [[ZNNeonButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [self.themedButtons addObject:button];
    return button;
}

- (ZNNeonFrameView *)frameCard {
    ZNNeonFrameView *view = [[ZNNeonFrameView alloc] initWithFrame:CGRectZero];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.themedFrames addObject:view];
    return view;
}

- (void)buildInterface {
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:self.panel];

    self.blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blur.frame = self.panel.bounds;
    self.blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blur.clipsToBounds = YES;
    [self.panel addSubview:self.blur];

    UIView *content = self.blur.contentView;
    self.washLayer = [CAGradientLayer layer];
    self.washLayer.name = @"ZNModifierWashV2";
    self.washLayer.startPoint = CGPointMake(0.0,0.0);
    self.washLayer.endPoint = CGPointMake(1.0,1.0);
    [content.layer insertSublayer:self.washLayer atIndex:0];

    self.logoView = [[ZNLogoView alloc] initWithFrame:CGRectZero];
    self.logoView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logoView.backgroundColor = UIColor.clearColor;
    self.titleLabel = L(@"霓虹 iOS 修改器", 16.5, UIFontWeightBold, UIColor.whiteColor);
    self.subtitleLabel = L(@"运行时内存控制台  ·  ARM64", 9.5, UIFontWeightMedium, UIColor.cyanColor);
    self.statusTag = L(@"当前进程", 9.0, UIFontWeightBold, UIColor.whiteColor);
    self.statusTag.textAlignment = NSTextAlignmentCenter;
    self.statusTag.layer.borderWidth = 1.0;
    self.statusTag.layer.masksToBounds = YES;
    self.styleButton = [self button:@"风格 01/20" selector:@selector(styleSelectorTapped)];
    [self.styleButton setNeonActive:YES];
    for (UIView *v in @[self.logoView,self.titleLabel,self.subtitleLabel,self.statusTag,self.styleButton]) [content addSubview:v];

    UIView *body = [[UIView alloc] initWithFrame:CGRectZero];
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [content addSubview:body];

    ZNNeonFrameView *nav = [self frameCard];
    ZNNeonFrameView *editor = [self frameCard];
    ZNNeonFrameView *inspector = [self frameCard];
    [body addSubview:nav]; [body addSubview:editor]; [body addSubview:inspector];

    UILabel *navTitle = L(@"工具箱", 10.5, UIFontWeightBold, UIColor.cyanColor);
    [self.accentLabels addObject:navTitle];
    [nav addSubview:navTitle];
    NSArray<NSString *> *navTitles = @[@"内存",@"模块",@"冻结",@"关于"];
    NSMutableArray *navButtons = [NSMutableArray array];
    for (NSInteger i=0;i<navTitles.count;i++) {
        ZNNeonButton *b = [self button:navTitles[i] selector:@selector(navTapped:)];
        b.tag = i;
        [b setNeonActive:(i==0)];
        [nav addSubview:b];
        [navButtons addObject:b];
    }
    self.navButtons = navButtons.copy;
    UILabel *scope = L(@"仅作用于\n当前注入进程", 8.7, UIFontWeightRegular, C(0.45,0.58,0.72,1));
    scope.numberOfLines = 2;
    [nav addSubview:scope];

    UILabel *editorTitle = L(@"直接地址编辑", 11.5, UIFontWeightSemibold, UIColor.cyanColor);
    UILabel *addressCaption = L(@"地址 / 模块 + RVA", 8.5, UIFontWeightMedium, C(0.48,0.61,0.78,1));
    UILabel *valueCaption = L(@"数值", 8.5, UIFontWeightMedium, C(0.48,0.61,0.78,1));
    [self.accentLabels addObject:editorTitle];
    self.addressField = [self fieldWithPlaceholder:@"0x12345678  /  UnityFramework+0x1A2B3C"];
    self.valueField = [self fieldWithPlaceholder:@"123 / 1.5 / 01 FF 90 00"];
    self.typeControl = [[UISegmentedControl alloc] initWithItems:@[@"I32",@"I64",@"F32",@"F64",@"HEX"]];
    self.typeControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.typeControl.selectedSegmentIndex = 2;
    ZNNeonButton *readButton = [self button:@"读取" selector:@selector(readTapped)];
    ZNNeonButton *writeButton = [self button:@"写入" selector:@selector(writeTapped)];
    [writeButton setNeonActive:YES];
    self.freezeButton = [self button:@"冻结" selector:@selector(freezeTapped)];
    ZNNeonButton *clearButton = [self button:@"清空" selector:@selector(clearTapped)];
    for (UIView *v in @[editorTitle,addressCaption,self.addressField,valueCaption,self.valueField,self.typeControl,readButton,writeButton,self.freezeButton,clearButton]) [editor addSubview:v];
    self.resolvedLabel = L(@"解析地址：—", 9.0, UIFontWeightMedium, UIColor.cyanColor);
    self.resolvedLabel.font = [UIFont monospacedSystemFontOfSize:9.0 weight:UIFontWeightMedium];
    [editor addSubview:self.resolvedLabel];

    self.logView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.logView.translatesAutoresizingMaskIntoConstraints = NO;
    self.logView.editable = NO;
    self.logView.selectable = YES;
    self.logView.font = [UIFont monospacedSystemFontOfSize:9.0 weight:UIFontWeightRegular];
    self.logView.layer.borderWidth = 1.0;
    self.logView.text = @"已就绪。请输入地址或 模块+RVA。";
    [editor addSubview:self.logView];

    UILabel *inspectorTitle = L(@"运行时检查器", 11.5, UIFontWeightSemibold, UIColor.magentaColor);
    UILabel *inspectorHint = L(@"镜像 / 基址 / 冻结状态", 8.4, UIFontWeightMedium, C(0.50,0.58,0.73,1));
    [self.accentLabels addObject:inspectorTitle];
    self.inspectorView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.inspectorView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inspectorView.editable = NO;
    self.inspectorView.selectable = YES;
    self.inspectorView.font = [UIFont monospacedSystemFontOfSize:8.7 weight:UIFontWeightRegular];
    [inspector addSubview:inspectorTitle]; [inspector addSubview:inspectorHint]; [inspector addSubview:self.inspectorView];

    self.footerLabel = L(@"霓虹修改器 V2  ·  同进程内存编辑  ·  iOS 13+ / arm64  ·  20款霓虹风格", 8.5, UIFontWeightMedium, C(0.40,0.54,0.68,1));
    [content addSubview:self.footerLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.logoView.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18],
        [self.logoView.topAnchor constraintEqualToAnchor:content.topAnchor constant:9],
        [self.logoView.widthAnchor constraintEqualToConstant:38], [self.logoView.heightAnchor constraintEqualToConstant:38],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.logoView.trailingAnchor constant:10],
        [self.titleLabel.topAnchor constraintEqualToAnchor:content.topAnchor constant:9],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:1],
        [self.statusTag.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
        [self.statusTag.centerYAnchor constraintEqualToAnchor:self.titleLabel.centerYAnchor],
        [self.statusTag.widthAnchor constraintEqualToConstant:72], [self.statusTag.heightAnchor constraintEqualToConstant:25],
        [self.styleButton.trailingAnchor constraintEqualToAnchor:self.statusTag.leadingAnchor constant:-7],
        [self.styleButton.centerYAnchor constraintEqualToAnchor:self.statusTag.centerYAnchor],
        [self.styleButton.widthAnchor constraintEqualToConstant:94], [self.styleButton.heightAnchor constraintEqualToConstant:28],

        [body.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:12], [body.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-12],
        [body.topAnchor constraintEqualToAnchor:content.topAnchor constant:56], [body.bottomAnchor constraintEqualToAnchor:self.footerLabel.topAnchor constant:-6],
        [nav.leadingAnchor constraintEqualToAnchor:body.leadingAnchor], [nav.topAnchor constraintEqualToAnchor:body.topAnchor], [nav.bottomAnchor constraintEqualToAnchor:body.bottomAnchor], [nav.widthAnchor constraintEqualToConstant:106],
        [editor.leadingAnchor constraintEqualToAnchor:nav.trailingAnchor constant:8], [editor.topAnchor constraintEqualToAnchor:body.topAnchor], [editor.bottomAnchor constraintEqualToAnchor:body.bottomAnchor],
        [inspector.leadingAnchor constraintEqualToAnchor:editor.trailingAnchor constant:8], [inspector.trailingAnchor constraintEqualToAnchor:body.trailingAnchor], [inspector.topAnchor constraintEqualToAnchor:body.topAnchor], [inspector.bottomAnchor constraintEqualToAnchor:body.bottomAnchor],
        [editor.widthAnchor constraintEqualToAnchor:body.widthAnchor multiplier:0.54 constant:-57], [inspector.widthAnchor constraintGreaterThanOrEqualToConstant:190],

        [navTitle.leadingAnchor constraintEqualToAnchor:nav.leadingAnchor constant:11], [navTitle.topAnchor constraintEqualToAnchor:nav.topAnchor constant:11],
        [self.navButtons[0].leadingAnchor constraintEqualToAnchor:nav.leadingAnchor constant:8], [self.navButtons[0].trailingAnchor constraintEqualToAnchor:nav.trailingAnchor constant:-8], [self.navButtons[0].topAnchor constraintEqualToAnchor:navTitle.bottomAnchor constant:9], [self.navButtons[0].heightAnchor constraintEqualToConstant:36],
        [self.navButtons[1].leadingAnchor constraintEqualToAnchor:self.navButtons[0].leadingAnchor], [self.navButtons[1].trailingAnchor constraintEqualToAnchor:self.navButtons[0].trailingAnchor], [self.navButtons[1].topAnchor constraintEqualToAnchor:self.navButtons[0].bottomAnchor constant:6], [self.navButtons[1].heightAnchor constraintEqualToAnchor:self.navButtons[0].heightAnchor],
        [self.navButtons[2].leadingAnchor constraintEqualToAnchor:self.navButtons[0].leadingAnchor], [self.navButtons[2].trailingAnchor constraintEqualToAnchor:self.navButtons[0].trailingAnchor], [self.navButtons[2].topAnchor constraintEqualToAnchor:self.navButtons[1].bottomAnchor constant:6], [self.navButtons[2].heightAnchor constraintEqualToAnchor:self.navButtons[0].heightAnchor],
        [self.navButtons[3].leadingAnchor constraintEqualToAnchor:self.navButtons[0].leadingAnchor], [self.navButtons[3].trailingAnchor constraintEqualToAnchor:self.navButtons[0].trailingAnchor], [self.navButtons[3].topAnchor constraintEqualToAnchor:self.navButtons[2].bottomAnchor constant:6], [self.navButtons[3].heightAnchor constraintEqualToAnchor:self.navButtons[0].heightAnchor],
        [scope.leadingAnchor constraintEqualToAnchor:nav.leadingAnchor constant:11], [scope.trailingAnchor constraintEqualToAnchor:nav.trailingAnchor constant:-8], [scope.bottomAnchor constraintEqualToAnchor:nav.bottomAnchor constant:-9],

        [editorTitle.leadingAnchor constraintEqualToAnchor:editor.leadingAnchor constant:12], [editorTitle.topAnchor constraintEqualToAnchor:editor.topAnchor constant:10],
        [addressCaption.leadingAnchor constraintEqualToAnchor:editorTitle.leadingAnchor], [addressCaption.topAnchor constraintEqualToAnchor:editorTitle.bottomAnchor constant:7],
        [self.addressField.leadingAnchor constraintEqualToAnchor:editor.leadingAnchor constant:11], [self.addressField.trailingAnchor constraintEqualToAnchor:editor.trailingAnchor constant:-11], [self.addressField.topAnchor constraintEqualToAnchor:addressCaption.bottomAnchor constant:3], [self.addressField.heightAnchor constraintEqualToConstant:32],
        [valueCaption.leadingAnchor constraintEqualToAnchor:editorTitle.leadingAnchor], [valueCaption.topAnchor constraintEqualToAnchor:self.addressField.bottomAnchor constant:6],
        [self.valueField.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor], [self.valueField.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor], [self.valueField.topAnchor constraintEqualToAnchor:valueCaption.bottomAnchor constant:3], [self.valueField.heightAnchor constraintEqualToConstant:32],
        [self.typeControl.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor], [self.typeControl.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor], [self.typeControl.topAnchor constraintEqualToAnchor:self.valueField.bottomAnchor constant:7], [self.typeControl.heightAnchor constraintEqualToConstant:29],
        [readButton.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor], [readButton.topAnchor constraintEqualToAnchor:self.typeControl.bottomAnchor constant:7], [readButton.heightAnchor constraintEqualToConstant:34],
        [writeButton.leadingAnchor constraintEqualToAnchor:readButton.trailingAnchor constant:6], [writeButton.topAnchor constraintEqualToAnchor:readButton.topAnchor], [writeButton.heightAnchor constraintEqualToAnchor:readButton.heightAnchor],
        [self.freezeButton.leadingAnchor constraintEqualToAnchor:writeButton.trailingAnchor constant:6], [self.freezeButton.topAnchor constraintEqualToAnchor:readButton.topAnchor], [self.freezeButton.heightAnchor constraintEqualToAnchor:readButton.heightAnchor],
        [clearButton.leadingAnchor constraintEqualToAnchor:self.freezeButton.trailingAnchor constant:6], [clearButton.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor], [clearButton.topAnchor constraintEqualToAnchor:readButton.topAnchor], [clearButton.heightAnchor constraintEqualToAnchor:readButton.heightAnchor],
        [writeButton.widthAnchor constraintEqualToAnchor:readButton.widthAnchor], [self.freezeButton.widthAnchor constraintEqualToAnchor:readButton.widthAnchor], [clearButton.widthAnchor constraintEqualToAnchor:readButton.widthAnchor],
        [self.resolvedLabel.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor], [self.resolvedLabel.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor], [self.resolvedLabel.topAnchor constraintEqualToAnchor:readButton.bottomAnchor constant:5],
        [self.logView.leadingAnchor constraintEqualToAnchor:self.addressField.leadingAnchor], [self.logView.trailingAnchor constraintEqualToAnchor:self.addressField.trailingAnchor], [self.logView.topAnchor constraintEqualToAnchor:self.resolvedLabel.bottomAnchor constant:4], [self.logView.bottomAnchor constraintEqualToAnchor:editor.bottomAnchor constant:-9],

        [inspectorTitle.leadingAnchor constraintEqualToAnchor:inspector.leadingAnchor constant:11], [inspectorTitle.topAnchor constraintEqualToAnchor:inspector.topAnchor constant:10],
        [inspectorHint.leadingAnchor constraintEqualToAnchor:inspectorTitle.leadingAnchor], [inspectorHint.topAnchor constraintEqualToAnchor:inspectorTitle.bottomAnchor constant:2],
        [self.inspectorView.leadingAnchor constraintEqualToAnchor:inspector.leadingAnchor constant:9], [self.inspectorView.trailingAnchor constraintEqualToAnchor:inspector.trailingAnchor constant:-9], [self.inspectorView.topAnchor constraintEqualToAnchor:inspectorHint.bottomAnchor constant:7], [self.inspectorView.bottomAnchor constraintEqualToAnchor:inspector.bottomAnchor constant:-9],
        [self.footerLabel.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18], [self.footerLabel.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-7], [self.footerLabel.heightAnchor constraintEqualToConstant:16]
    ]];

    [self buildStyleSelectorInView:content];
}

- (void)buildStyleSelectorInView:(UIView *)content {
    self.stylePanel = [self frameCard];
    self.stylePanel.translatesAutoresizingMaskIntoConstraints = YES;
    self.stylePanel.hidden = YES;
    self.stylePanel.alpha = 0.0;
    [content addSubview:self.stylePanel];

    self.stylePanelTitle = L(@"选择霓虹风格", 15.0, UIFontWeightBold, UIColor.whiteColor);
    self.stylePanelHint = L(@"20款独立配色 / 圆角 / 边框 / 发光参数，选择后自动保存", 9.0, UIFontWeightMedium, C(0.55,0.66,0.80,1));
    ZNNeonButton *close = [self button:@"关闭" selector:@selector(styleSelectorTapped)];
    [self.stylePanel addSubview:self.stylePanelTitle]; [self.stylePanel addSubview:self.stylePanelHint]; [self.stylePanel addSubview:close];

    UIStackView *column = [[UIStackView alloc] initWithFrame:CGRectZero];
    column.translatesAutoresizingMaskIntoConstraints = NO;
    column.axis = UILayoutConstraintAxisVertical;
    column.distribution = UIStackViewDistributionFillEqually;
    column.spacing = 6.0;
    [self.stylePanel addSubview:column];

    NSArray *themes = ZNThemeCatalog();
    NSMutableArray *choices = [NSMutableArray array];
    for (NSInteger row=0; row<5; row++) {
        UIStackView *line = [[UIStackView alloc] initWithFrame:CGRectZero];
        line.axis = UILayoutConstraintAxisHorizontal;
        line.distribution = UIStackViewDistributionFillEqually;
        line.spacing = 6.0;
        [column addArrangedSubview:line];
        for (NSInteger col=0; col<4; col++) {
            NSInteger idx = row*4+col;
            NSDictionary *theme = themes[idx];
            ZNNeonButton *b = [[ZNNeonButton alloc] initWithFrame:CGRectZero];
            b.tag = idx;
            b.titleLabel.font = [UIFont systemFontOfSize:9.8 weight:UIFontWeightSemibold];
            [b setTitle:[NSString stringWithFormat:@"%02ld  %@", (long)(idx+1), theme[ZNThemeNameKey]] forState:UIControlStateNormal];
            [b applyTheme:theme];
            [b setNeonActive:(idx==self.selectedThemeIndex)];
            [b addTarget:self action:@selector(themeChoiceTapped:) forControlEvents:UIControlEventTouchUpInside];
            [line addArrangedSubview:b];
            [choices addObject:b];
        }
    }
    self.themeChoiceButtons = choices.copy;

    [NSLayoutConstraint activateConstraints:@[
        [self.stylePanelTitle.leadingAnchor constraintEqualToAnchor:self.stylePanel.leadingAnchor constant:16], [self.stylePanelTitle.topAnchor constraintEqualToAnchor:self.stylePanel.topAnchor constant:13],
        [self.stylePanelHint.leadingAnchor constraintEqualToAnchor:self.stylePanelTitle.leadingAnchor], [self.stylePanelHint.topAnchor constraintEqualToAnchor:self.stylePanelTitle.bottomAnchor constant:2],
        [close.trailingAnchor constraintEqualToAnchor:self.stylePanel.trailingAnchor constant:-12], [close.topAnchor constraintEqualToAnchor:self.stylePanel.topAnchor constant:11], [close.widthAnchor constraintEqualToConstant:62], [close.heightAnchor constraintEqualToConstant:28],
        [column.leadingAnchor constraintEqualToAnchor:self.stylePanel.leadingAnchor constant:12], [column.trailingAnchor constraintEqualToAnchor:self.stylePanel.trailingAnchor constant:-12], [column.topAnchor constraintEqualToAnchor:self.stylePanelHint.bottomAnchor constant:10], [column.bottomAnchor constraintEqualToAnchor:self.stylePanel.bottomAnchor constant:-12]
    ]];
}

- (void)applyThemeAtIndex:(NSInteger)index persist:(BOOL)persist {
    NSArray *themes = ZNThemeCatalog();
    if (index < 0 || index >= (NSInteger)themes.count) index = 0;
    self.selectedThemeIndex = index;
    NSDictionary *theme = themes[index];
    UIColor *primary = theme[ZNThemePrimaryKey];
    UIColor *secondary = theme[ZNThemeSecondaryKey];
    UIColor *surface = theme[ZNThemeSurfaceKey];
    UIColor *surfaceAlt = theme[ZNThemeSurfaceAltKey];
    UIColor *text = theme[ZNThemeTextKey];
    UIColor *muted = theme[ZNThemeMutedKey];
    CGFloat corner = [theme[ZNThemeCornerKey] doubleValue];
    CGFloat shadow = [theme[ZNThemeShadowKey] doubleValue];

    self.panel.layer.cornerRadius = corner + 6.0;
    self.blur.layer.cornerRadius = corner + 6.0;
    self.panel.layer.shadowColor = secondary.CGColor;
    self.panel.layer.shadowOpacity = shadow;
    self.panel.layer.shadowRadius = 22.0;
    self.washLayer.colors = @[(id)[primary colorWithAlphaComponent:0.23].CGColor, (id)C(0.01,0.01,0.03,0.22).CGColor, (id)[secondary colorWithAlphaComponent:0.22].CGColor];
    [self.logoView applyTheme:theme];
    self.subtitleLabel.textColor = primary;
    self.statusTag.textColor = text;
    self.statusTag.backgroundColor = [primary colorWithAlphaComponent:0.12];
    self.statusTag.layer.borderColor = [primary colorWithAlphaComponent:0.60].CGColor;
    self.statusTag.layer.cornerRadius = MAX(5.0, corner*0.45);
    self.footerLabel.textColor = muted;
    self.stylePanelTitle.textColor = text;
    self.stylePanelHint.textColor = muted;

    for (ZNNeonFrameView *frame in self.themedFrames) [frame applyTheme:theme];
    for (ZNNeonButton *button in self.themedButtons) [button applyTheme:theme];
    for (UILabel *label in self.accentLabels) label.textColor = primary;

    NSArray *fields = @[self.addressField,self.valueField];
    for (UITextField *field in fields) {
        field.backgroundColor = surfaceAlt;
        field.textColor = text;
        field.tintColor = primary;
        field.layer.cornerRadius = MAX(5.0, corner*0.52);
        field.layer.borderColor = [primary colorWithAlphaComponent:0.46].CGColor;
    }
    self.typeControl.selectedSegmentTintColor = [primary colorWithAlphaComponent:0.28];
    [self.typeControl setTitleTextAttributes:@{NSForegroundColorAttributeName:muted, NSFontAttributeName:[UIFont systemFontOfSize:9.5 weight:UIFontWeightSemibold]} forState:UIControlStateNormal];
    [self.typeControl setTitleTextAttributes:@{NSForegroundColorAttributeName:text, NSFontAttributeName:[UIFont systemFontOfSize:9.5 weight:UIFontWeightBold]} forState:UIControlStateSelected];

    self.logView.backgroundColor = [surface colorWithAlphaComponent:0.72];
    self.logView.textColor = [text colorWithAlphaComponent:0.86];
    self.logView.layer.cornerRadius = MAX(5.0, corner*0.5);
    self.logView.layer.borderColor = [primary colorWithAlphaComponent:0.32].CGColor;
    self.inspectorView.backgroundColor = [surface colorWithAlphaComponent:0.70];
    self.inspectorView.textColor = [text colorWithAlphaComponent:0.88];
    self.inspectorView.layer.cornerRadius = MAX(5.0, corner*0.5);
    self.resolvedLabel.textColor = primary;
    [self.styleButton setTitle:[NSString stringWithFormat:@"风格 %02ld/20", (long)(index+1)] forState:UIControlStateNormal];
    [self.styleButton setNeonActive:YES];

    for (ZNNeonButton *choice in self.themeChoiceButtons) [choice setNeonActive:(choice.tag==index)];
    if (persist) {
        [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"ZNNeonModifierThemeIndex"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self appendLog:[NSString stringWithFormat:@"风格已切换：%02ld · %@", (long)(index+1), theme[ZNThemeNameKey]]];
    }
}

- (void)styleSelectorTapped {
    BOOL showing = !self.stylePanel.hidden;
    if (!showing) {
        self.stylePanel.hidden = NO;
        [self.blur.contentView bringSubviewToFront:self.stylePanel];
        self.stylePanel.transform = CGAffineTransformMakeScale(0.96,0.96);
        [UIView animateWithDuration:0.18 animations:^{ self.stylePanel.alpha=1.0; self.stylePanel.transform=CGAffineTransformIdentity; }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{ self.stylePanel.alpha=0.0; self.stylePanel.transform=CGAffineTransformMakeScale(0.97,0.97); } completion:^(__unused BOOL finished){ self.stylePanel.hidden=YES; }];
    }
}

- (void)themeChoiceTapped:(ZNNeonButton *)sender {
    [self applyThemeAtIndex:sender.tag persist:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.12*NSEC_PER_SEC)),dispatch_get_main_queue(),^{ if (!self.stylePanel.hidden) [self styleSelectorTapped]; });
}

- (ZNMemoryValueType)selectedType {
    NSInteger index = self.typeControl.selectedSegmentIndex;
    if (index < 0 || index > ZNMemoryValueTypeHexBytes) return ZNMemoryValueTypeFloat32;
    return (ZNMemoryValueType)index;
}

- (void)appendLog:(NSString *)line {
    NSString *current = self.logView.text ?: @"";
    NSString *next = current.length ? [current stringByAppendingFormat:@"\n%@",line] : line;
    NSArray *lines = [next componentsSeparatedByString:@"\n"];
    if (lines.count > 7) lines = [lines subarrayWithRange:NSMakeRange(lines.count-7,7)];
    self.logView.text = [lines componentsJoinedByString:@"\n"];
    if (self.logView.text.length) [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length-1,1)];
}

- (void)updateResolvedAddress {
    NSString *error = nil;
    NSNumber *address = [[ZNMemoryEngine shared] resolveAddressExpression:self.addressField.text ?: @"" error:&error];
    NSDictionary *theme = ZNThemeCatalog()[self.selectedThemeIndex];
    if (address) {
        self.resolvedLabel.text = [NSString stringWithFormat:@"解析地址：0x%llX",address.unsignedLongLongValue];
        self.resolvedLabel.textColor = theme[ZNThemePrimaryKey];
    } else {
        self.resolvedLabel.text = [NSString stringWithFormat:@"解析地址：%@",error ?: @"—"];
        self.resolvedLabel.textColor = C(1.0,0.32,0.50,1.0);
    }
    BOOL frozen = [[ZNMemoryEngine shared] isFrozenExpression:self.addressField.text ?: @""];
    [self.freezeButton setTitle:(frozen ? @"解冻" : @"冻结") forState:UIControlStateNormal];
    [self.freezeButton setNeonActive:frozen];
}

- (void)readTapped {
    [self.view endEditing:YES];
    NSString *error=nil;
    NSString *value=[[ZNMemoryEngine shared] readValueAtExpression:self.addressField.text ?: @"" type:self.selectedType error:&error];
    if (value) {
        self.valueField.text=value;
        [self appendLog:[NSString stringWithFormat:@"读取  %@  => %@",self.addressField.text ?: @"",value]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":@"memory_read",@"value":value}];
    } else [self appendLog:[NSString stringWithFormat:@"错误  %@",error ?: @"读取失败"]];
    [self updateResolvedAddress];
}

- (void)writeTapped {
    [self.view endEditing:YES];
    NSString *error=nil;
    BOOL ok=[[ZNMemoryEngine shared] writeValue:self.valueField.text ?: @"" atExpression:self.addressField.text ?: @"" type:self.selectedType error:&error];
    if (ok) {
        [self appendLog:[NSString stringWithFormat:@"写入  %@  <= %@",self.addressField.text ?: @"",self.valueField.text ?: @""]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":@"memory_write",@"value":self.valueField.text ?: @""}];
    } else [self appendLog:[NSString stringWithFormat:@"错误  %@",error ?: @"写入失败"]];
    [self updateResolvedAddress];
}

- (void)freezeTapped {
    [self.view endEditing:YES];
    NSString *expression=self.addressField.text ?: @"";
    BOOL frozen=[[ZNMemoryEngine shared] isFrozenExpression:expression];
    NSString *error=nil;
    BOOL ok=[[ZNMemoryEngine shared] setFrozen:!frozen expression:expression type:self.selectedType value:self.valueField.text ?: @"" error:&error];
    if (ok) { [self appendLog:[NSString stringWithFormat:@"%@  %@",frozen?@"解除冻结":@"开始冻结",expression]]; [self refreshFreezeState]; }
    else [self appendLog:[NSString stringWithFormat:@"错误  %@",error ?: @"冻结操作失败"]];
    [self updateResolvedAddress];
}

- (void)clearTapped {
    self.addressField.text=@""; self.valueField.text=@""; self.resolvedLabel.text=@"解析地址：—";
    self.logView.text=@"已就绪。请输入地址或 模块+RVA。";
    [self.freezeButton setTitle:@"冻结" forState:UIControlStateNormal]; [self.freezeButton setNeonActive:NO];
    [self.view endEditing:YES];
}

- (void)refreshModules {
    NSArray *modules=[[ZNMemoryEngine shared] loadedModules];
    NSMutableString *text=[NSMutableString string];
    NSUInteger shown=MIN((NSUInteger)18,modules.count);
    for (NSUInteger i=0;i<shown;i++) {
        NSDictionary *module=modules[i];
        [text appendFormat:@"%@\n基址 0x%llX\n\n",module[@"name"],[module[@"base"] unsignedLongLongValue]];
    }
    if (modules.count>shown) [text appendFormat:@"… 另有 %lu 个镜像",(unsigned long)(modules.count-shown)];
    self.inspectorView.text=text.length?text:@"未发现 dyld 镜像。";
}

- (void)refreshFreezeState {
    NSArray *entries=[[ZNMemoryEngine shared] frozenEntries];
    if (!entries.count) { self.inspectorView.text=@"当前没有冻结项。\n\n冻结功能大约每 150 ms 将选定值重新写回同一地址。"; return; }
    NSMutableString *text=[NSMutableString stringWithFormat:@"冻结项：%lu\n\n",(unsigned long)entries.count];
    for (NSDictionary *entry in entries) [text appendFormat:@"%@\n= %@\n\n",entry[@"expression"],entry[@"value"]];
    self.inspectorView.text=text;
}

- (void)navTapped:(ZNNeonButton *)sender {
    for (ZNNeonButton *button in self.navButtons) [button setNeonActive:(button==sender)];
    switch (sender.tag) {
        case 0: self.inspectorView.text=@"内存模式\n\n支持绝对地址或 模块+RVA。\n“读取”读取当前值；“写入”修改当前进程；HEX 默认读取 16 字节，写入输入的字节序列。"; break;
        case 1: [self refreshModules]; break;
        case 2: [self refreshFreezeState]; break;
        default: self.inspectorView.text=@"霓虹 iOS 修改器 V2\n\n原生 UIKit + Mach VM\narm64 / iOS 13+\n\n作用域：加载本 dylib 的当前进程。\n地址格式：\n  0x12345678\n  main+0x1234\n  UnityFramework+0x1234\n\n顶部“风格”按钮可切换 20 款霓虹菜单样式。"; break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField==self.addressField) [self updateResolvedAddress];
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds=self.view.bounds; UIEdgeInsets safe=self.view.safeAreaInsets;
    CGFloat aw=CGRectGetWidth(bounds)-safe.left-safe.right, ah=CGRectGetHeight(bounds)-safe.top-safe.bottom;
    CGFloat width=MIN(940.0,MAX(650.0,aw-16.0)), height=MIN(460.0,MAX(350.0,ah-8.0));
    width=MIN(width,aw-6.0); height=MIN(height,ah-4.0);
    self.panel.frame=CGRectIntegral(CGRectMake(safe.left+(aw-width)*0.5,safe.top+(ah-height)*0.5,width,height));
    self.blur.frame=self.panel.bounds; self.washLayer.frame=self.blur.contentView.bounds;
    CGFloat sw=MIN(640.0,MAX(520.0,width-70.0)); sw=MIN(sw,width-24.0);
    CGFloat sh=MIN(330.0,MAX(285.0,height-72.0)); sh=MIN(sh,height-34.0);
    self.stylePanel.frame=CGRectIntegral(CGRectMake((width-sw)*0.5,(height-sh)*0.5,sw,sh));
}

- (void)toggleMenu { [self setMenuVisible:!self.menuVisible animated:YES]; }
- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated {
    self.menuVisible=visible;
    void (^changes)(void)=^{ self.panel.alpha=visible?1.0:0.0; self.panel.transform=visible?CGAffineTransformIdentity:CGAffineTransformMakeScale(0.965,0.965); };
    if (!animated) { changes(); self.panel.hidden=!visible; return; }
    if (visible) { self.panel.hidden=NO; [self refreshModules]; }
    [UIView animateWithDuration:0.20 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState animations:changes completion:^(__unused BOOL finished){ if(!visible) self.panel.hidden=YES; }];
}

@end
