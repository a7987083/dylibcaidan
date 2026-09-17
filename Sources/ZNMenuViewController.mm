#import "ZNMenuViewController.h"
#import "ZNMemoryEngine.h"
#import <QuartzCore/QuartzCore.h>

NSNotificationName const ZNMenuValueChangedNotification = @"ZNMenuValueChangedNotification";

static UIColor *C(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

static UILabel *L(NSString *text, CGFloat size, UIFontWeight weight, UIColor *color) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    return label;
}

static NSArray<NSString *> *ZNLayoutNames(void) {
    static NSArray<NSString *> *names;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        names = @[
            @"经典三栏", @"顶栏工作台", @"底部停靠", @"右侧工具栏", @"镜像三栏",
            @"左栏双层", @"卡片矩阵", @"编辑器优先", @"检查器优先", @"中央核心",
            @"宽屏控制台", @"终端主视图", @"双栏均分", @"上下堆叠", @"左右堆叠",
            @"浮动卡片", @"HUD 十字", @"工控台", @"极简面板", @"赛博仪表盘"
        ];
    });
    return names;
}

@interface ZNNeonCard : UIView
@property (nonatomic, strong) CAGradientLayer *borderGradient;
@property (nonatomic, strong) CAShapeLayer *borderMask;
@end

@implementation ZNNeonCard
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = C(0.012, 0.030, 0.072, 0.90);
    self.layer.cornerRadius = 14.0;
    self.layer.shadowColor = C(0.58, 0.05, 1.0, 1.0).CGColor;
    self.layer.shadowOpacity = 0.24;
    self.layer.shadowRadius = 12.0;
    self.layer.shadowOffset = CGSizeZero;

    _borderGradient = [CAGradientLayer layer];
    _borderGradient.startPoint = CGPointMake(0.0, 0.35);
    _borderGradient.endPoint = CGPointMake(1.0, 0.65);
    _borderGradient.colors = @[
        (id)C(0.00, 0.94, 1.00, 0.95).CGColor,
        (id)C(0.36, 0.34, 1.00, 0.82).CGColor,
        (id)C(0.98, 0.08, 0.92, 0.95).CGColor
    ];
    _borderMask = [CAShapeLayer layer];
    _borderMask.fillColor = UIColor.clearColor.CGColor;
    _borderMask.strokeColor = UIColor.whiteColor.CGColor;
    _borderMask.lineWidth = 1.3;
    _borderGradient.mask = _borderMask;
    [self.layer addSublayer:_borderGradient];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.borderGradient.frame = self.bounds;
    self.borderMask.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.8, 0.8)
                                                       cornerRadius:MAX(1.0, self.layer.cornerRadius - 0.8)].CGPath;
}
@end

@interface ZNLogoView : UIView
@end

@implementation ZNLogoView
- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) return;
    CGContextSetLineCap(ctx, kCGLineCapRound);
    CGContextSetLineWidth(ctx, 3.6);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 7.0, C(0.0, 0.94, 1.0, 0.95).CGColor);
    CGContextSetStrokeColorWithColor(ctx, C(0.0, 0.94, 1.0, 1.0).CGColor);
    CGContextMoveToPoint(ctx, 8, 8);
    CGContextAddLineToPoint(ctx, CGRectGetWidth(rect) - 8, CGRectGetHeight(rect) - 8);
    CGContextStrokePath(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeZero, 7.0, C(0.98, 0.08, 0.92, 0.95).CGColor);
    CGContextSetStrokeColorWithColor(ctx, C(0.98, 0.10, 0.94, 1.0).CGColor);
    CGContextMoveToPoint(ctx, CGRectGetWidth(rect) - 8, 8);
    CGContextAddLineToPoint(ctx, 8, CGRectGetHeight(rect) - 8);
    CGContextStrokePath(ctx);
}
@end

@interface ZNNeonButton : UIButton
@property (nonatomic, assign) BOOL neonActive;
@property (nonatomic, assign) NSInteger layoutVariant;
- (void)setNeonActive:(BOOL)active;
- (void)applyLayoutVariant:(NSInteger)variant;
@end

@implementation ZNNeonButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.68;
    self.contentEdgeInsets = UIEdgeInsetsMake(3, 7, 3, 7);
    _layoutVariant = 0;
    _neonActive = NO;
    [self applyAppearance];
    return self;
}

- (void)setNeonActive:(BOOL)active {
    _neonActive = active;
    [self applyAppearance];
}

- (void)applyLayoutVariant:(NSInteger)variant {
    _layoutVariant = variant;
    [self applyAppearance];
}

- (void)applyAppearance {
    NSInteger v = MAX(0, MIN(19, self.layoutVariant));
    NSArray<NSNumber *> *radii = @[@8,@6,@12,@2,@10,@4,@16,@7,@14,@9,@3,@11,@18,@5,@13,@20,@1,@8,@15,@6];
    NSArray<NSNumber *> *borders = @[@1.1,@1.0,@1.2,@1.6,@1.0,@1.4,@0.9,@1.2,@1.1,@1.3,@1.8,@1.0,@0.9,@1.5,@1.1,@0.8,@2.0,@1.4,@0.9,@1.7];
    NSArray<NSNumber *> *fonts = @[@10.5,@10.2,@10.6,@9.8,@10.4,@10.0,@10.7,@10.3,@10.6,@10.4,@9.9,@10.5,@10.7,@10.0,@10.5,@10.8,@9.8,@10.3,@10.7,@10.1];
    CGFloat radius = radii[v].doubleValue;
    CGFloat border = borders[v].doubleValue;
    CGFloat font = fonts[v].doubleValue;
    self.layer.cornerRadius = radius;
    self.layer.borderWidth = border;
    self.titleLabel.font = [UIFont systemFontOfSize:font weight:((v==3 || v==10 || v==16 || v==19) ? UIFontWeightBold : UIFontWeightSemibold)];
    self.backgroundColor = self.neonActive ? C(0.00, 0.58, 0.74, 0.23) : C(0.025, 0.060, 0.125, 0.82);
    self.layer.borderColor = (self.neonActive ? C(0.0, 0.94, 1.0, 0.98) : C(0.20, 0.52, 0.78, 0.58)).CGColor;
    self.layer.shadowColor = ((v==4 || v==8 || v==11 || v==17) ? C(0.96,0.08,0.92,1.0) : C(0.0,0.94,1.0,1.0)).CGColor;
    self.layer.shadowOpacity = self.neonActive ? (0.30 + 0.02 * (v % 6)) : 0.05;
    self.layer.shadowRadius = self.neonActive ? (5.5 + (v % 5)) : 2.0;
    self.layer.shadowOffset = CGSizeZero;
    [self setTitleColor:(self.neonActive ? C(0.83, 1.0, 1.0, 1.0) : C(0.66, 0.78, 0.92, 1.0)) forState:UIControlStateNormal];
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
@property (nonatomic, strong) ZNNeonButton *layoutButton;
@property (nonatomic, strong) UILabel *footerLabel;

@property (nonatomic, strong) ZNNeonCard *navCard;
@property (nonatomic, strong) ZNNeonCard *editorCard;
@property (nonatomic, strong) ZNNeonCard *inspectorCard;
@property (nonatomic, strong) UILabel *navTitle;
@property (nonatomic, strong) UILabel *scopeLabel;
@property (nonatomic, strong) NSArray<ZNNeonButton *> *navButtons;

@property (nonatomic, strong) UILabel *editorTitle;
@property (nonatomic, strong) UILabel *addressCaption;
@property (nonatomic, strong) UILabel *valueCaption;
@property (nonatomic, strong) UITextField *addressField;
@property (nonatomic, strong) UITextField *valueField;
@property (nonatomic, strong) UISegmentedControl *typeControl;
@property (nonatomic, strong) ZNNeonButton *readButton;
@property (nonatomic, strong) ZNNeonButton *writeButton;
@property (nonatomic, strong) ZNNeonButton *freezeButton;
@property (nonatomic, strong) ZNNeonButton *clearButton;
@property (nonatomic, strong) UILabel *resolvedLabel;
@property (nonatomic, strong) UITextView *logView;

@property (nonatomic, strong) UILabel *inspectorTitle;
@property (nonatomic, strong) UILabel *inspectorHint;
@property (nonatomic, strong) UITextView *inspectorView;

@property (nonatomic, strong) UIView *pickerDim;
@property (nonatomic, strong) ZNNeonCard *pickerCard;
@property (nonatomic, strong) UILabel *pickerTitle;
@property (nonatomic, strong) ZNNeonButton *pickerCloseButton;
@property (nonatomic, strong) NSArray<ZNNeonButton *> *pickerButtons;
@property (nonatomic, strong) NSMutableArray<ZNNeonButton *> *allButtons;

@property (nonatomic, assign) NSInteger selectedLayoutIndex;
@property (nonatomic, assign) BOOL pickerVisible;
@property (nonatomic, assign, getter=isMenuVisible) BOOL menuVisible;
@end

@implementation ZNMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.allButtons = [NSMutableArray array];
    NSInteger saved = [[NSUserDefaults standardUserDefaults] integerForKey:@"ZNNeonModifierLayoutIndex"];
    self.selectedLayoutIndex = (saved >= 0 && saved < 20) ? saved : 0;
    [self buildInterface];
    [self applyLayoutControlStyle];
    [self refreshModules];
    [self setMenuVisible:NO animated:NO];
}

- (UITextField *)fieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectZero];
    field.backgroundColor = C(0.006, 0.020, 0.052, 0.94);
    field.textColor = UIColor.whiteColor;
    field.tintColor = C(0.0, 0.94, 1.0, 1.0);
    field.font = [UIFont monospacedSystemFontOfSize:11.5 weight:UIFontWeightMedium];
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
                                                                  attributes:@{NSForegroundColorAttributeName:C(0.36,0.48,0.64,1.0)}];
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0,0,9,1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.delegate = self;
    return field;
}

- (ZNNeonButton *)button:(NSString *)title selector:(SEL)selector {
    ZNNeonButton *button = [[ZNNeonButton alloc] initWithFrame:CGRectZero];
    [button setTitle:title forState:UIControlStateNormal];
    if (selector) [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [self.allButtons addObject:button];
    return button;
}

- (void)buildInterface {
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.layer.cornerRadius = 22.0;
    self.panel.layer.borderWidth = 1.0;
    self.panel.layer.borderColor = C(0.0, 0.88, 1.0, 0.48).CGColor;
    self.panel.layer.shadowColor = C(0.70, 0.03, 1.0, 1.0).CGColor;
    self.panel.layer.shadowOpacity = 0.34;
    self.panel.layer.shadowRadius = 22.0;
    self.panel.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:self.panel];

    self.blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    self.blur.layer.cornerRadius = 22.0;
    self.blur.clipsToBounds = YES;
    [self.panel addSubview:self.blur];

    UIView *content = self.blur.contentView;
    self.washLayer = [CAGradientLayer layer];
    self.washLayer.startPoint = CGPointMake(0.0,0.0);
    self.washLayer.endPoint = CGPointMake(1.0,1.0);
    self.washLayer.colors = @[
        (id)C(0.00,0.30,0.48,0.29).CGColor,
        (id)C(0.035,0.018,0.13,0.18).CGColor,
        (id)C(0.48,0.00,0.60,0.24).CGColor
    ];
    [content.layer insertSublayer:self.washLayer atIndex:0];

    self.logoView = [[ZNLogoView alloc] initWithFrame:CGRectZero];
    self.logoView.backgroundColor = UIColor.clearColor;
    self.titleLabel = L(@"霓虹 iOS 修改器", 16.5, UIFontWeightBold, UIColor.whiteColor);
    self.subtitleLabel = L(@"运行时内存控制台  ·  ARM64", 9.5, UIFontWeightMedium, C(0.48,0.80,0.94,1.0));
    self.statusTag = L(@"当前进程", 9.0, UIFontWeightBold, C(0.78,1.0,1.0,1.0));
    self.statusTag.textAlignment = NSTextAlignmentCenter;
    self.statusTag.backgroundColor = C(0.0,0.52,0.70,0.16);
    self.statusTag.layer.borderWidth = 1.0;
    self.statusTag.layer.borderColor = C(0.0,0.90,1.0,0.60).CGColor;
    self.statusTag.layer.cornerRadius = 8.0;
    self.statusTag.layer.masksToBounds = YES;
    self.layoutButton = [self button:@"布局 01/20" selector:@selector(layoutSelectorTapped)];
    [self.layoutButton setNeonActive:YES];
    for (UIView *v in @[self.logoView,self.titleLabel,self.subtitleLabel,self.statusTag,self.layoutButton]) [content addSubview:v];

    self.navCard = [[ZNNeonCard alloc] initWithFrame:CGRectZero];
    self.editorCard = [[ZNNeonCard alloc] initWithFrame:CGRectZero];
    self.inspectorCard = [[ZNNeonCard alloc] initWithFrame:CGRectZero];
    [content addSubview:self.navCard];
    [content addSubview:self.editorCard];
    [content addSubview:self.inspectorCard];

    self.navTitle = L(@"工具箱", 10.5, UIFontWeightBold, C(0.42,0.90,1.0,1.0));
    [self.navCard addSubview:self.navTitle];
    NSArray<NSString *> *navTitles = @[@"内存", @"模块", @"冻结", @"关于"];
    NSMutableArray *nav = [NSMutableArray array];
    for (NSInteger i=0;i<4;i++) {
        ZNNeonButton *b = [self button:navTitles[i] selector:@selector(navTapped:)];
        b.tag = i;
        [b setNeonActive:(i==0)];
        [self.navCard addSubview:b];
        [nav addObject:b];
    }
    self.navButtons = nav.copy;
    self.scopeLabel = L(@"仅作用于当前注入进程", 8.5, UIFontWeightRegular, C(0.42,0.58,0.74,1.0));
    self.scopeLabel.numberOfLines = 2;
    [self.navCard addSubview:self.scopeLabel];

    self.editorTitle = L(@"直接地址编辑", 11.5, UIFontWeightSemibold, C(0.54,0.92,1.0,1.0));
    self.addressCaption = L(@"地址 / 模块 + RVA", 8.5, UIFontWeightMedium, C(0.48,0.62,0.80,1.0));
    self.valueCaption = L(@"数值", 8.5, UIFontWeightMedium, C(0.48,0.62,0.80,1.0));
    self.addressField = [self fieldWithPlaceholder:@"0x12345678  /  UnityFramework+0x1A2B3C"];
    self.valueField = [self fieldWithPlaceholder:@"123 / 1.5 / 01 FF 90 00"];
    self.typeControl = [[UISegmentedControl alloc] initWithItems:@[@"I32",@"I64",@"F32",@"F64",@"HEX"]];
    self.typeControl.selectedSegmentIndex = 2;
    self.readButton = [self button:@"读取" selector:@selector(readTapped)];
    self.writeButton = [self button:@"写入" selector:@selector(writeTapped)];
    [self.writeButton setNeonActive:YES];
    self.freezeButton = [self button:@"冻结" selector:@selector(freezeTapped)];
    self.clearButton = [self button:@"清空" selector:@selector(clearTapped)];
    self.resolvedLabel = L(@"解析地址：—", 9.0, UIFontWeightMedium, C(0.0,0.90,1.0,1.0));
    self.resolvedLabel.font = [UIFont monospacedSystemFontOfSize:9.0 weight:UIFontWeightMedium];
    self.logView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.logView.editable = NO;
    self.logView.selectable = YES;
    self.logView.backgroundColor = C(0.003,0.012,0.032,0.74);
    self.logView.textColor = C(0.62,0.84,0.94,1.0);
    self.logView.font = [UIFont monospacedSystemFontOfSize:8.8 weight:UIFontWeightRegular];
    self.logView.text = @"已就绪。请输入地址或 模块+RVA。";
    self.logView.layer.borderWidth = 1.0;
    self.logView.layer.borderColor = C(0.08,0.40,0.60,0.46).CGColor;
    for (UIView *v in @[self.editorTitle,self.addressCaption,self.addressField,self.valueCaption,self.valueField,self.typeControl,self.readButton,self.writeButton,self.freezeButton,self.clearButton,self.resolvedLabel,self.logView]) {
        [self.editorCard addSubview:v];
    }

    self.inspectorTitle = L(@"运行时检查器", 11.5, UIFontWeightSemibold, C(0.88,0.52,1.0,1.0));
    self.inspectorHint = L(@"镜像 / 基址 / 冻结状态", 8.4, UIFontWeightMedium, C(0.50,0.60,0.75,1.0));
    self.inspectorView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.inspectorView.editable = NO;
    self.inspectorView.selectable = YES;
    self.inspectorView.backgroundColor = C(0.003,0.012,0.032,0.70);
    self.inspectorView.textColor = C(0.72,0.78,0.93,1.0);
    self.inspectorView.font = [UIFont monospacedSystemFontOfSize:8.5 weight:UIFontWeightRegular];
    for (UIView *v in @[self.inspectorTitle,self.inspectorHint,self.inspectorView]) [self.inspectorCard addSubview:v];

    self.footerLabel = L(@"霓虹修改器 V3  ·  中文  ·  20套布局  ·  iOS 13+ / arm64", 8.5, UIFontWeightMedium, C(0.38,0.54,0.70,1.0));
    [content addSubview:self.footerLabel];

    self.pickerDim = [[UIView alloc] initWithFrame:CGRectZero];
    self.pickerDim.backgroundColor = C(0.0,0.0,0.02,0.62);
    self.pickerDim.hidden = YES;
    [content addSubview:self.pickerDim];
    self.pickerCard = [[ZNNeonCard alloc] initWithFrame:CGRectZero];
    self.pickerCard.hidden = YES;
    [content addSubview:self.pickerCard];
    self.pickerTitle = L(@"选择布局风格  ·  20 套", 13.0, UIFontWeightBold, UIColor.whiteColor);
    [self.pickerCard addSubview:self.pickerTitle];
    self.pickerCloseButton = [self button:@"关闭" selector:@selector(closeLayoutSelector)];
    [self.pickerCard addSubview:self.pickerCloseButton];
    NSMutableArray *picker = [NSMutableArray array];
    [ZNLayoutNames() enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        ZNNeonButton *b = [self button:[NSString stringWithFormat:@"%02lu  %@", (unsigned long)idx+1, name]
                              selector:@selector(layoutOptionTapped:)];
        b.tag = (NSInteger)idx;
        [self.pickerCard addSubview:b];
        [picker addObject:b];
    }];
    self.pickerButtons = picker.copy;
}

- (void)applyLayoutControlStyle {
    NSInteger variant = self.selectedLayoutIndex;
    for (ZNNeonButton *button in self.allButtons) [button applyLayoutVariant:variant];
    [self.layoutButton setNeonActive:YES];
    [self.writeButton setNeonActive:YES];
    for (NSInteger i=0;i<self.pickerButtons.count;i++) {
        [self.pickerButtons[i] setNeonActive:(i == self.selectedLayoutIndex)];
    }

    NSArray<NSNumber *> *radii = @[@8,@6,@12,@2,@10,@4,@16,@7,@14,@9,@3,@11,@18,@5,@13,@20,@1,@8,@15,@6];
    NSArray<NSNumber *> *borders = @[@1.1,@1.0,@1.2,@1.6,@1.0,@1.4,@0.9,@1.2,@1.1,@1.3,@1.8,@1.0,@0.9,@1.5,@1.1,@0.8,@2.0,@1.4,@0.9,@1.7];
    CGFloat radius = radii[variant].doubleValue;
    CGFloat border = borders[variant].doubleValue;
    for (UITextField *field in @[self.addressField,self.valueField]) {
        field.layer.cornerRadius = radius;
        field.layer.borderWidth = border;
        field.layer.borderColor = C(0.06,0.58,0.82,0.62).CGColor;
    }
    self.logView.layer.cornerRadius = radius;
    self.inspectorView.layer.cornerRadius = radius;
    self.typeControl.layer.cornerRadius = radius;
    self.typeControl.layer.masksToBounds = YES;
    self.typeControl.selectedSegmentTintColor = C(0.0,0.62,0.76,0.34);
    [self.typeControl setTitleTextAttributes:@{NSForegroundColorAttributeName:C(0.56,0.68,0.84,1), NSFontAttributeName:[UIFont systemFontOfSize:9.2 weight:UIFontWeightSemibold]} forState:UIControlStateNormal];
    [self.typeControl setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor, NSFontAttributeName:[UIFont systemFontOfSize:9.2 weight:UIFontWeightBold]} forState:UIControlStateSelected];

    NSArray<NSNumber *> *cardRadii = @[@14,@12,@16,@5,@13,@8,@18,@10,@17,@14,@7,@15,@20,@9,@16,@22,@4,@12,@18,@8];
    CGFloat cardRadius = cardRadii[variant].doubleValue;
    for (ZNNeonCard *card in @[self.navCard,self.editorCard,self.inspectorCard,self.pickerCard]) {
        card.layer.cornerRadius = cardRadius;
        [card setNeedsLayout];
    }
    NSString *name = ZNLayoutNames()[self.selectedLayoutIndex];
    [self.layoutButton setTitle:[NSString stringWithFormat:@"布局 %02ld/20 · %@", (long)self.selectedLayoutIndex+1, name] forState:UIControlStateNormal];
    self.footerLabel.text = [NSString stringWithFormat:@"霓虹修改器 V3  ·  当前布局：%@  ·  iOS 13+ / arm64", name];
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
        self.resolvedLabel.text = [NSString stringWithFormat:@"解析地址：0x%llX", address.unsignedLongLongValue];
        self.resolvedLabel.textColor = C(0.0,0.92,1.0,1.0);
    } else {
        self.resolvedLabel.text = [NSString stringWithFormat:@"解析地址：%@", error ?: @"—"];
        self.resolvedLabel.textColor = C(1.0,0.36,0.62,1.0);
    }
    BOOL frozen = [[ZNMemoryEngine shared] isFrozenExpression:self.addressField.text ?: @""];
    [self.freezeButton setTitle:(frozen ? @"取消冻结" : @"冻结") forState:UIControlStateNormal];
    [self.freezeButton setNeonActive:frozen];
}

- (void)readTapped {
    [self.view endEditing:YES];
    NSString *error = nil;
    NSString *value = [[ZNMemoryEngine shared] readValueAtExpression:self.addressField.text ?: @"" type:self.selectedType error:&error];
    if (value) {
        self.valueField.text = value;
        [self appendLog:[NSString stringWithFormat:@"读取  %@  => %@", self.addressField.text ?: @"", value]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":@"memory_read",@"value":value}];
    } else {
        [self appendLog:[NSString stringWithFormat:@"错误  %@", error ?: @"读取失败"]];
    }
    [self updateResolvedAddress];
}

- (void)writeTapped {
    [self.view endEditing:YES];
    NSString *error = nil;
    BOOL ok = [[ZNMemoryEngine shared] writeValue:self.valueField.text ?: @""
                                     atExpression:self.addressField.text ?: @""
                                             type:self.selectedType
                                            error:&error];
    if (ok) {
        [self appendLog:[NSString stringWithFormat:@"写入  %@  <= %@", self.addressField.text ?: @"", self.valueField.text ?: @""]];
        [[NSNotificationCenter defaultCenter] postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":@"memory_write",@"value":self.valueField.text ?: @""}];
    } else {
        [self appendLog:[NSString stringWithFormat:@"错误  %@", error ?: @"写入失败"]];
    }
    [self updateResolvedAddress];
}

- (void)freezeTapped {
    [self.view endEditing:YES];
    NSString *expression = self.addressField.text ?: @"";
    BOOL frozen = [[ZNMemoryEngine shared] isFrozenExpression:expression];
    NSString *error = nil;
    BOOL ok = [[ZNMemoryEngine shared] setFrozen:!frozen
                                      expression:expression
                                            type:self.selectedType
                                           value:self.valueField.text ?: @""
                                           error:&error];
    if (ok) {
        [self appendLog:[NSString stringWithFormat:@"%@  %@", frozen ? @"取消冻结" : @"冻结", expression]];
        [self refreshFreezeState];
    } else {
        [self appendLog:[NSString stringWithFormat:@"错误  %@", error ?: @"冻结失败"]];
    }
    [self updateResolvedAddress];
}

- (void)clearTapped {
    self.addressField.text = @"";
    self.valueField.text = @"";
    self.resolvedLabel.text = @"解析地址：—";
    self.logView.text = @"已就绪。请输入地址或 模块+RVA。";
    [self.freezeButton setTitle:@"冻结" forState:UIControlStateNormal];
    [self.freezeButton setNeonActive:NO];
    [self.view endEditing:YES];
}

- (void)refreshModules {
    NSArray<NSDictionary<NSString *, id> *> *modules = [[ZNMemoryEngine shared] loadedModules];
    NSMutableString *text = [NSMutableString string];
    NSUInteger shown = MIN((NSUInteger)18, modules.count);
    for (NSUInteger i=0;i<shown;i++) {
        NSDictionary *module = modules[i];
        [text appendFormat:@"%@\n0x%llX\n\n", module[@"name"], [module[@"base"] unsignedLongLongValue]];
    }
    if (modules.count > shown) [text appendFormat:@"… 另有 %lu 个镜像", (unsigned long)(modules.count - shown)];
    self.inspectorView.text = text.length ? text : @"未发现 dyld 镜像。";
}

- (void)refreshFreezeState {
    NSArray<NSDictionary<NSString *, id> *> *entries = [[ZNMemoryEngine shared] frozenEntries];
    if (entries.count == 0) {
        self.inspectorView.text = @"暂无冻结项。\n\n冻结会约每 150ms 将所选数值写回同一地址。";
        return;
    }
    NSMutableString *text = [NSMutableString stringWithFormat:@"冻结项：%lu\n\n", (unsigned long)entries.count];
    for (NSDictionary *entry in entries) {
        [text appendFormat:@"%@\n= %@\n\n", entry[@"expression"], entry[@"value"]];
    }
    self.inspectorView.text = text;
}

- (void)navTapped:(ZNNeonButton *)sender {
    for (ZNNeonButton *button in self.navButtons) [button setNeonActive:(button == sender)];
    switch (sender.tag) {
        case 0:
            self.inspectorView.text = @"内存模式\n\n支持绝对地址或 模块+RVA。读取获取当前值；写入修改当前进程；HEX 默认读取 16 字节。";
            break;
        case 1: [self refreshModules]; break;
        case 2: [self refreshFreezeState]; break;
        default:
            self.inspectorView.text = @"霓虹 iOS 修改器 V3\n\nNative UIKit + Mach VM\narm64 / iOS 13+\n\n作用范围：加载本 dylib 的当前进程。\n\n地址格式：\n0x12345678\nmain+0x1234\nUnityFramework+0x1234";
            break;
    }
}

- (void)layoutSelectorTapped {
    self.pickerVisible = !self.pickerVisible;
    self.pickerDim.hidden = !self.pickerVisible;
    self.pickerCard.hidden = !self.pickerVisible;
    if (self.pickerVisible) {
        [self.blur.contentView bringSubviewToFront:self.pickerDim];
        [self.blur.contentView bringSubviewToFront:self.pickerCard];
        [self.view setNeedsLayout];
    }
}

- (void)closeLayoutSelector {
    self.pickerVisible = NO;
    self.pickerDim.hidden = YES;
    self.pickerCard.hidden = YES;
}

- (void)layoutOptionTapped:(ZNNeonButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= 20) return;
    self.selectedLayoutIndex = index;
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:@"ZNNeonModifierLayoutIndex"];
    [self applyLayoutControlStyle];
    [self closeLayoutSelector];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self appendLog:[NSString stringWithFormat:@"布局已切换：%02ld %@", (long)index+1, ZNLayoutNames()[index]]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":@"layout",@"value":@(index)}];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.addressField) [self updateResolvedAddress];
    return YES;
}

- (void)layoutNavContents {
    CGRect b = self.navCard.bounds;
    CGFloat pad = 9.0;
    self.navTitle.frame = CGRectMake(pad, 8, MAX(40,b.size.width-2*pad), 16);
    BOOL horizontal = b.size.width > 300 || b.size.height < 125;
    if (horizontal) {
        CGFloat titleW = MIN(62.0, b.size.width * 0.13);
        self.navTitle.frame = CGRectMake(pad, 7, titleW, 18);
        CGFloat x = CGRectGetMaxX(self.navTitle.frame) + 7;
        CGFloat scopeW = MIN(132.0, b.size.width * 0.18);
        CGFloat available = MAX(120.0, b.size.width - x - scopeW - pad - 8);
        CGFloat bw = (available - 18.0) / 4.0;
        for (NSInteger i=0;i<4;i++) self.navButtons[i].frame = CGRectMake(x + i*(bw+6), 7, bw, MAX(30.0,b.size.height-14));
        self.scopeLabel.frame = CGRectMake(b.size.width - scopeW - pad, 7, scopeW, MAX(30.0,b.size.height-14));
        self.scopeLabel.textAlignment = NSTextAlignmentRight;
    } else {
        self.scopeLabel.textAlignment = NSTextAlignmentLeft;
        CGFloat top = 30.0;
        CGFloat bottomSpace = 34.0;
        CGFloat available = MAX(100.0, b.size.height - top - bottomSpace - 10.0);
        CGFloat bh = MIN(38.0, MAX(25.0, (available - 15.0)/4.0));
        for (NSInteger i=0;i<4;i++) self.navButtons[i].frame = CGRectMake(pad, top + i*(bh+5), MAX(40,b.size.width-2*pad), bh);
        self.scopeLabel.frame = CGRectMake(pad, MAX(top + 4*(bh+5), b.size.height-bottomSpace), MAX(40,b.size.width-2*pad), bottomSpace-4);
    }
}

- (void)layoutEditorContents {
    CGRect b = self.editorCard.bounds;
    CGFloat w = b.size.width, h = b.size.height;
    CGFloat pad = MAX(8.0, MIN(12.0, w*0.035));
    CGFloat scale = MIN(1.0, MAX(0.72, h/300.0));
    CGFloat titleH = 18.0;
    CGFloat capH = 12.0;
    CGFloat fieldH = 31.0 * scale;
    CGFloat segH = 28.0 * scale;
    CGFloat buttonH = 33.0 * scale;
    CGFloat gap = 5.0 * scale;
    CGFloat y = 8.0;
    self.editorTitle.frame = CGRectMake(pad,y,w-2*pad,titleH); y += titleH + 4;
    self.addressCaption.frame = CGRectMake(pad,y,w-2*pad,capH); y += capH + 2;
    self.addressField.frame = CGRectMake(pad,y,w-2*pad,fieldH); y += fieldH + gap;
    self.valueCaption.frame = CGRectMake(pad,y,w-2*pad,capH); y += capH + 2;
    self.valueField.frame = CGRectMake(pad,y,w-2*pad,fieldH); y += fieldH + gap;
    self.typeControl.frame = CGRectMake(pad,y,w-2*pad,segH); y += segH + gap;
    CGFloat bw = MAX(42.0, (w-2*pad-18.0)/4.0);
    self.readButton.frame = CGRectMake(pad,y,bw,buttonH);
    self.writeButton.frame = CGRectMake(pad+bw+6,y,bw,buttonH);
    self.freezeButton.frame = CGRectMake(pad+2*(bw+6),y,bw,buttonH);
    self.clearButton.frame = CGRectMake(pad+3*(bw+6),y,MAX(42,w-pad-(pad+3*(bw+6))),buttonH);
    y += buttonH + 4;
    self.resolvedLabel.frame = CGRectMake(pad,y,w-2*pad,14); y += 17;
    self.logView.frame = CGRectMake(pad,y,w-2*pad,MAX(34,h-y-pad));
}

- (void)layoutInspectorContents {
    CGRect b = self.inspectorCard.bounds;
    CGFloat pad = 10.0;
    self.inspectorTitle.frame = CGRectMake(pad,8,MAX(40,b.size.width-2*pad),18);
    self.inspectorHint.frame = CGRectMake(pad,26,MAX(40,b.size.width-2*pad),14);
    self.inspectorView.frame = CGRectMake(pad,44,MAX(40,b.size.width-2*pad),MAX(30,b.size.height-54));
}

- (void)setPanelFramesForLayoutInRect:(CGRect)a {
    CGFloat x=a.origin.x,y=a.origin.y,w=a.size.width,h=a.size.height,g=8.0;
    CGRect n=CGRectZero,e=CGRectZero,i=CGRectZero;
    switch (self.selectedLayoutIndex) {
        case 0: {
            CGFloat nw=w*0.15, ew=w*0.53;
            n=CGRectMake(x,y,nw,h); e=CGRectMake(x+nw+g,y,ew-g,h); i=CGRectMake(CGRectGetMaxX(e)+g,y,w-nw-ew-g,h);
        } break;
        case 1: {
            CGFloat nh=58; n=CGRectMake(x,y,w,nh); CGFloat rem=h-nh-g; CGFloat ew=w*0.62;
            e=CGRectMake(x,y+nh+g,ew-g,rem); i=CGRectMake(x+ew,y+nh+g,w-ew,rem);
        } break;
        case 2: {
            CGFloat nh=58; CGFloat rem=h-nh-g; CGFloat ew=w*0.64;
            e=CGRectMake(x,y,ew-g,rem); i=CGRectMake(x+ew,y,w-ew,rem); n=CGRectMake(x,y+rem+g,w,nh);
        } break;
        case 3: {
            CGFloat nw=w*0.15, iw=w*0.29;
            e=CGRectMake(x,y,w-nw-iw-2*g,h); i=CGRectMake(CGRectGetMaxX(e)+g,y,iw,h); n=CGRectMake(CGRectGetMaxX(i)+g,y,nw,h);
        } break;
        case 4: {
            CGFloat iw=w*0.31,nw=w*0.15;
            i=CGRectMake(x,y,iw,h); e=CGRectMake(x+iw+g,y,w-iw-nw-2*g,h); n=CGRectMake(CGRectGetMaxX(e)+g,y,nw,h);
        } break;
        case 5: {
            CGFloat lw=w*0.25, top=h*0.48;
            n=CGRectMake(x,y,lw-g,top-g*0.5); i=CGRectMake(x,y+top+g*0.5,lw-g,h-top-g*0.5); e=CGRectMake(x+lw,y,w-lw,h);
        } break;
        case 6: {
            CGFloat top=h*0.56, left=w*0.28;
            n=CGRectMake(x,y,left-g,top-g*0.5); e=CGRectMake(x+left,y,w-left,top-g*0.5); i=CGRectMake(x,y+top+g*0.5,w,h-top-g*0.5);
        } break;
        case 7: {
            CGFloat nh=50, ih=h*0.24;
            n=CGRectMake(x,y,w,nh); e=CGRectMake(x,y+nh+g,w,h-nh-ih-2*g); i=CGRectMake(x,y+h-ih,w,ih);
        } break;
        case 8: {
            CGFloat nw=w*0.14, eh=h*0.42;
            n=CGRectMake(x,y,nw,h); e=CGRectMake(x+nw+g,y,w-nw-g,eh-g*0.5); i=CGRectMake(x+nw+g,y+eh+g*0.5,w-nw-g,h-eh-g*0.5);
        } break;
        case 9: {
            CGFloat side=w*0.20;
            n=CGRectMake(x,y,side-g,h); e=CGRectMake(x+side,y,w-2*side,h); i=CGRectMake(x+w-side+g,y,side-g,h);
        } break;
        case 10: {
            CGFloat nh=48;
            n=CGRectMake(x,y,w*0.42,nh); i=CGRectMake(x+w*0.42+g,y,w*0.58-g,nh); e=CGRectMake(x,y+nh+g,w,h-nh-g);
        } break;
        case 11: {
            CGFloat left=w*0.58, nh=54;
            i=CGRectMake(x,y,left-g,h); n=CGRectMake(x+left,y,w-left,nh); e=CGRectMake(x+left,y+nh+g,w-left,h-nh-g);
        } break;
        case 12: {
            CGFloat nh=52, half=(w-g)*0.5;
            n=CGRectMake(x,y,w,nh); e=CGRectMake(x,y+nh+g,half,h-nh-g); i=CGRectMake(x+half+g,y+nh+g,half,h-nh-g);
        } break;
        case 13: {
            CGFloat nh=52, body=h-nh-g, eh=body*0.58;
            n=CGRectMake(x,y,w,nh); e=CGRectMake(x,y+nh+g,w,eh-g*0.5); i=CGRectMake(x,y+nh+g+eh+g*0.5,w,body-eh-g*0.5);
        } break;
        case 14: {
            CGFloat nw=w*0.18, right=w-nw-g, eh=h*0.55;
            n=CGRectMake(x,y,nw,h); e=CGRectMake(x+nw+g,y,right,eh-g*0.5); i=CGRectMake(x+nw+g,y+eh+g*0.5,right,h-eh-g*0.5);
        } break;
        case 15: {
            CGFloat nw=w*0.22, iw=w*0.28;
            e=CGRectMake(x+nw*0.55,y+h*0.06,w-nw*0.75-iw*0.65,h*0.88);
            n=CGRectMake(x,y,nw,h*0.46); i=CGRectMake(x+w-iw,y+h*0.52,iw,h*0.48);
        } break;
        case 16: {
            CGFloat nh=54, iw=w*0.24, centerW=w-iw-g;
            n=CGRectMake(x+centerW*0.12,y,centerW*0.76,nh); e=CGRectMake(x,y+nh+g,centerW,h-nh-g); i=CGRectMake(x+centerW+g,y,iw,h);
        } break;
        case 17: {
            CGFloat nw=w*0.20, ih=h*0.28;
            n=CGRectMake(x,y,nw,h-ih-g); e=CGRectMake(x+nw+g,y,w-nw-g,h-ih-g); i=CGRectMake(x,y+h-ih,w,ih);
        } break;
        case 18: {
            CGFloat nh=48, iw=w*0.23;
            n=CGRectMake(x,y,w-iw-g,nh); i=CGRectMake(x+w-iw,y,iw,nh); e=CGRectMake(x,y+nh+g,w,h-nh-g);
        } break;
        default: {
            CGFloat nw=w*0.19;
            n=CGRectMake(x,y,nw,h*0.58); i=CGRectMake(x,y+h*0.58+g,nw,h-h*0.58-g); e=CGRectMake(x+nw+g,y,w-nw-g,h);
        } break;
    }
    self.navCard.frame = CGRectIntegral(n);
    self.editorCard.frame = CGRectIntegral(e);
    self.inspectorCard.frame = CGRectIntegral(i);
}

- (void)layoutPickerInBounds:(CGRect)b {
    self.pickerDim.frame = b;
    CGFloat w = MIN(780.0, MAX(320.0, b.size.width - 90.0));
    CGFloat h = MIN(380.0, MAX(270.0, b.size.height - 70.0));
    w = MIN(w, b.size.width - 18.0); h = MIN(h, b.size.height - 18.0);
    self.pickerCard.frame = CGRectIntegral(CGRectMake((b.size.width-w)/2.0, (b.size.height-h)/2.0, w, h));
    CGRect p = self.pickerCard.bounds;
    self.pickerTitle.frame = CGRectMake(16,10,p.size.width-120,24);
    self.pickerCloseButton.frame = CGRectMake(p.size.width-88,8,72,28);
    NSInteger cols = p.size.width >= 620 ? 4 : 2;
    NSInteger rows = (20 + cols - 1)/cols;
    CGFloat gap=7.0, top=46.0, bottom=12.0;
    CGFloat bw=(p.size.width-24.0-(cols-1)*gap)/cols;
    CGFloat bh=MAX(30.0,(p.size.height-top-bottom-(rows-1)*gap)/rows);
    for (NSInteger idx=0;idx<20;idx++) {
        NSInteger r=idx/cols,c=idx%cols;
        self.pickerButtons[idx].frame = CGRectIntegral(CGRectMake(12+c*(bw+gap),top+r*(bh+gap),bw,bh));
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat aw = MAX(1.0, CGRectGetWidth(bounds)-safe.left-safe.right);
    CGFloat ah = MAX(1.0, CGRectGetHeight(bounds)-safe.top-safe.bottom);
    CGFloat width = MIN(980.0, MAX(320.0, aw-12.0));
    CGFloat height = MIN(500.0, MAX(300.0, ah-8.0));
    width = MIN(width, aw-4.0); height = MIN(height, ah-4.0);
    self.panel.frame = CGRectIntegral(CGRectMake(safe.left+(aw-width)/2.0, safe.top+(ah-height)/2.0, width, height));
    self.blur.frame = self.panel.bounds;
    self.washLayer.frame = self.blur.contentView.bounds;

    CGRect c = self.blur.contentView.bounds;
    self.logoView.frame = CGRectMake(17,8,38,38);
    self.titleLabel.frame = CGRectMake(64,7,220,22);
    self.subtitleLabel.frame = CGRectMake(64,28,240,15);
    self.statusTag.frame = CGRectMake(c.size.width-92,10,76,25);
    CGFloat layoutW = MIN(210.0, MAX(120.0, c.size.width*0.23));
    self.layoutButton.frame = CGRectMake(CGRectGetMinX(self.statusTag.frame)-layoutW-7,8,layoutW,29);
    self.footerLabel.frame = CGRectMake(17,c.size.height-22,MAX(100,c.size.width-34),15);

    CGRect area = CGRectMake(12,52,MAX(100,c.size.width-24),MAX(80,c.size.height-80));
    if (area.size.width < 620.0) {
        CGFloat nh=50, ih=MAX(90,area.size.height*0.28);
        self.navCard.frame = CGRectMake(area.origin.x,area.origin.y,area.size.width,nh);
        self.editorCard.frame = CGRectMake(area.origin.x,area.origin.y+nh+7,area.size.width,MAX(120,area.size.height-nh-ih-14));
        self.inspectorCard.frame = CGRectMake(area.origin.x,CGRectGetMaxY(self.editorCard.frame)+7,area.size.width,ih);
    } else {
        [self setPanelFramesForLayoutInRect:area];
    }
    [self layoutNavContents];
    [self layoutEditorContents];
    [self layoutInspectorContents];
    [self layoutPickerInBounds:c];
}

- (void)toggleMenu {
    [self setMenuVisible:!self.menuVisible animated:YES];
}

- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated {
    self.menuVisible = visible;
    void (^changes)(void) = ^{
        self.panel.alpha = visible ? 1.0 : 0.0;
        self.panel.transform = visible ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.965,0.965);
    };
    if (!animated) {
        changes(); self.panel.hidden = !visible; return;
    }
    if (visible) {
        self.panel.hidden = NO;
        [self refreshModules];
    } else {
        [self closeLayoutSelector];
    }
    [UIView animateWithDuration:0.20 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState animations:changes completion:^(__unused BOOL finished){ if(!visible) self.panel.hidden=YES; }];
}

@end
