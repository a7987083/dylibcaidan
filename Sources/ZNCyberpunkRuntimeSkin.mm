#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// UI-only skin for the v0.5.6.2 SEALED runtime menu.
// No patch/runtime/builder/protection logic lives in this file.

static UIColor *ZNCyColor(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

static UIColor *ZNCyCyan(void)    { return ZNCyColor(0.05, 0.88, 1.00, 1.0); }
static UIColor *ZNCyCyanSoft(void){ return ZNCyColor(0.20, 0.72, 1.00, 1.0); }
static UIColor *ZNCyPurple(void)  { return ZNCyColor(0.78, 0.08, 1.00, 1.0); }
static UIColor *ZNCyPink(void)    { return ZNCyColor(1.00, 0.05, 0.72, 1.0); }
static UIColor *ZNCyPanel(void)   { return ZNCyColor(0.015, 0.035, 0.085, 0.96); }
static UIColor *ZNCyCard(void)    { return ZNCyColor(0.020, 0.070, 0.135, 0.88); }
static UIColor *ZNCyControl(void) { return ZNCyColor(0.025, 0.100, 0.180, 0.90); }
static UIColor *ZNCyMuted(void)   { return ZNCyColor(0.56, 0.72, 0.90, 1.0); }

static const void *kZNCyPanelFillKey = &kZNCyPanelFillKey;
static const void *kZNCyPanelBorderKey = &kZNCyPanelBorderKey;
static const void *kZNCyFloatFillKey = &kZNCyFloatFillKey;

@interface ZNRuntimeMenuControllerV040 : NSObject
+ (instancetype)shared;
@property(nonatomic,strong) UIButton *floatButton;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UIView *headerView;
@property(nonatomic,strong) UILabel *titleLabel;
@property(nonatomic,strong) UILabel *subtitleLabel;
@property(nonatomic,strong) UIView *readyDot;
@property(nonatomic,strong) UILabel *readyLabel;
@property(nonatomic,strong) UIButton *themeButton;
@property(nonatomic,strong) UIButton *modeButton;
@property(nonatomic,strong) UIButton *closeButton;
@property(nonatomic,strong) UIView *sidebarView;
@property(nonatomic,strong) UIScrollView *contentScroll;
@property(nonatomic,strong) UIView *contentView;
@property(nonatomic,strong) UIView *footerView;
@property(nonatomic,strong) UILabel *footerLabel;
@property(nonatomic,strong) NSMutableArray<UIButton *> *sidebarButtons;
@property(nonatomic,copy) NSArray<NSString *> *categories;
@property(nonatomic,assign) NSInteger selectedCategory;
@property(nonatomic,weak) UIWindow *hostWindow;
@property(nonatomic,assign) BOOL compactMode;
@property(nonatomic,assign) BOOL uiReady;
@property(nonatomic,assign) CGFloat menuAlpha;
- (void)layoutPanel;
- (void)applyTheme;
- (void)updateSidebar;
- (void)layoutSidebar;
- (void)renderPage;
- (UIView *)cardAtY:(CGFloat)y height:(CGFloat)h width:(CGFloat)w compact:(BOOL)compact;
- (CGSize)fullSizeForWindow:(UIWindow *)window;
- (CGSize)compactSizeForWindow:(UIWindow *)window;
- (void)makeUI:(UIWindow *)window;
@end

static void ZNCyUpdatePanelLayers(UIView *panel) {
    if (!panel) return;
    CAGradientLayer *fill = objc_getAssociatedObject(panel, kZNCyPanelFillKey);
    if (!fill) {
        fill = [CAGradientLayer layer];
        fill.name = @"ZNCyberPanelFill";
        fill.startPoint = CGPointMake(0.0, 0.0);
        fill.endPoint = CGPointMake(1.0, 1.0);
        fill.colors = @[(id)ZNCyColor(0.005,0.045,0.105,0.98).CGColor,
                        (id)ZNCyColor(0.025,0.030,0.105,0.97).CGColor,
                        (id)ZNCyColor(0.135,0.010,0.175,0.95).CGColor];
        [panel.layer insertSublayer:fill atIndex:0];
        objc_setAssociatedObject(panel, kZNCyPanelFillKey, fill, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    fill.frame = panel.bounds;
    fill.cornerRadius = 22.0;

    CAGradientLayer *border = objc_getAssociatedObject(panel, kZNCyPanelBorderKey);
    if (!border) {
        border = [CAGradientLayer layer];
        border.name = @"ZNCyberPanelBorder";
        border.startPoint = CGPointMake(0.0, 0.1);
        border.endPoint = CGPointMake(1.0, 0.9);
        border.colors = @[(id)ZNCyCyan().CGColor,
                          (id)ZNCyColor(0.18,0.44,1.0,1.0).CGColor,
                          (id)ZNCyPurple().CGColor,
                          (id)ZNCyPink().CGColor];
        [panel.layer addSublayer:border];
        objc_setAssociatedObject(panel, kZNCyPanelBorderKey, border, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    border.frame = panel.bounds;
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(panel.bounds, 0.8, 0.8)
                                            cornerRadius:21.2].CGPath;
    mask.fillColor = UIColor.clearColor.CGColor;
    mask.strokeColor = UIColor.whiteColor.CGColor;
    mask.lineWidth = 1.6;
    border.mask = mask;

    panel.backgroundColor = UIColor.clearColor;
    panel.layer.cornerRadius = 22.0;
    panel.layer.borderWidth = 0.0;
    panel.layer.shadowColor = ZNCyPurple().CGColor;
    panel.layer.shadowOpacity = 0.48;
    panel.layer.shadowRadius = 22.0;
    panel.layer.shadowOffset = CGSizeZero;
}

static void ZNCyStyleFloatingButton(UIButton *button) {
    if (!button) return;
    [button setTitle:@"X" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:20.0 weight:UIFontWeightBlack];
    button.backgroundColor = ZNCyColor(0.015,0.045,0.10,0.97);
    button.layer.cornerRadius = CGRectGetHeight(button.bounds) * 0.5;
    button.layer.borderWidth = 1.4;
    button.layer.borderColor = ZNCyCyan().CGColor;
    button.layer.shadowColor = ZNCyPurple().CGColor;
    button.layer.shadowOpacity = 0.78;
    button.layer.shadowRadius = 12.0;
    button.layer.shadowOffset = CGSizeZero;

    CAGradientLayer *fill = objc_getAssociatedObject(button, kZNCyFloatFillKey);
    if (!fill) {
        fill = [CAGradientLayer layer];
        fill.startPoint = CGPointMake(0,0);
        fill.endPoint = CGPointMake(1,1);
        fill.colors = @[(id)ZNCyColor(0.00,0.55,0.78,0.48).CGColor,
                        (id)ZNCyColor(0.55,0.00,0.82,0.42).CGColor];
        [button.layer insertSublayer:fill atIndex:0];
        objc_setAssociatedObject(button, kZNCyFloatFillKey, fill, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    fill.frame = button.bounds;
    fill.cornerRadius = button.layer.cornerRadius;
}

static void ZNCyStyleSlider(UISlider *slider) {
    slider.minimumTrackTintColor = ZNCyCyan();
    slider.maximumTrackTintColor = ZNCyColor(0.18,0.28,0.46,0.80);
    slider.thumbTintColor = UIColor.whiteColor;
    slider.layer.shadowColor = ZNCyCyan().CGColor;
    slider.layer.shadowOpacity = 0.25;
    slider.layer.shadowRadius = 4.0;
    slider.layer.shadowOffset = CGSizeZero;
}

static void ZNCyStyleSwitch(UISwitch *sw) {
    sw.onTintColor = ZNCyColor(0.00,0.78,0.90,1.0);
    sw.tintColor = ZNCyColor(0.14,0.22,0.34,1.0);
    sw.thumbTintColor = UIColor.whiteColor;
    sw.layer.shadowColor = ZNCyCyan().CGColor;
    sw.layer.shadowOpacity = 0.30;
    sw.layer.shadowRadius = 5.0;
    sw.layer.shadowOffset = CGSizeZero;
}

static void ZNCyStyleButton(UIButton *button, BOOL selected) {
    if (!button) return;
    button.backgroundColor = selected ? ZNCyColor(0.015,0.19,0.31,0.94) : ZNCyControl();
    button.tintColor = selected ? ZNCyCyan() : ZNCyCyanSoft();
    [button setTitleColor:selected ? ZNCyColor(0.76,0.97,1.0,1.0) : ZNCyColor(0.68,0.80,0.94,1.0)
                 forState:UIControlStateNormal];
    button.layer.cornerRadius = 10.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = (selected ? ZNCyCyan() : ZNCyColor(0.20,0.48,0.76,0.58)).CGColor;
    button.layer.shadowColor = (selected ? ZNCyCyan() : ZNCyPurple()).CGColor;
    button.layer.shadowOpacity = selected ? 0.52 : 0.14;
    button.layer.shadowRadius = selected ? 8.0 : 4.0;
    button.layer.shadowOffset = CGSizeZero;
}

static void ZNCyStyleTextField(UITextField *field) {
    field.backgroundColor = ZNCyColor(0.015,0.055,0.12,0.94);
    field.textColor = UIColor.whiteColor;
    field.tintColor = ZNCyCyan();
    field.layer.cornerRadius = 8.0;
    field.layer.borderWidth = 1.0;
    field.layer.borderColor = ZNCyColor(0.16,0.62,0.90,0.62).CGColor;
}

static void ZNCyStyleTree(UIView *root) {
    for (UIView *v in root.subviews) {
        if ([v isKindOfClass:UISlider.class]) ZNCyStyleSlider((UISlider *)v);
        else if ([v isKindOfClass:UISwitch.class]) ZNCyStyleSwitch((UISwitch *)v);
        else if ([v isKindOfClass:UITextField.class]) ZNCyStyleTextField((UITextField *)v);
        else if ([v isKindOfClass:UIButton.class]) {
            UIButton *b = (UIButton *)v;
            if (b.tag < 3000 || b.tag >= 4000) ZNCyStyleButton(b, NO);
        }
        ZNCyStyleTree(v);
    }
}

static void ZNCyStyleCard(UIView *card, BOOL compact) {
    card.backgroundColor = ZNCyCard();
    card.layer.cornerRadius = compact ? 10.0 : 13.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = ZNCyColor(0.12,0.69,0.96,0.58).CGColor;
    card.layer.shadowColor = ZNCyCyan().CGColor;
    card.layer.shadowOpacity = compact ? 0.12 : 0.18;
    card.layer.shadowRadius = compact ? 4.0 : 7.0;
    card.layer.shadowOffset = CGSizeZero;

    CAGradientLayer *g = [CAGradientLayer layer];
    g.name = @"ZNCyberCardFill";
    g.frame = card.bounds;
    g.cornerRadius = card.layer.cornerRadius;
    g.startPoint = CGPointMake(0,0);
    g.endPoint = CGPointMake(1,1);
    g.colors = @[(id)ZNCyColor(0.015,0.090,0.17,0.90).CGColor,
                 (id)ZNCyColor(0.025,0.035,0.12,0.86).CGColor,
                 (id)ZNCyColor(0.11,0.012,0.16,0.72).CGColor];
    [card.layer insertSublayer:g atIndex:0];
}

static UILabel *ZNCyLabelWithTag(UIView *parent, NSInteger tag) {
    UIView *existing = [parent viewWithTag:tag];
    if ([existing isKindOfClass:UILabel.class]) return (UILabel *)existing;
    UILabel *label = [UILabel new];
    label.tag = tag;
    label.userInteractionEnabled = NO;
    [parent addSubview:label];
    return label;
}

static void ZNCyStyleHeader(ZNRuntimeMenuControllerV040 *self) {
    if (!self.headerView) return;
    self.headerView.backgroundColor = ZNCyColor(0.012,0.045,0.095,0.92);
    self.headerView.layer.cornerRadius = 18.0;
    self.headerView.layer.borderWidth = 0.0;

    UILabel *logo = ZNCyLabelWithTag(self.headerView, 95630);
    logo.text = @"X";
    logo.textColor = ZNCyCyan();
    logo.font = [UIFont systemFontOfSize:34 weight:UIFontWeightBlack];
    logo.textAlignment = NSTextAlignmentCenter;
    logo.layer.shadowColor = ZNCyPurple().CGColor;
    logo.layer.shadowOpacity = 0.92;
    logo.layer.shadowRadius = 8.0;
    logo.layer.shadowOffset = CGSizeZero;

    UILabel *tagline = ZNCyLabelWithTag(self.headerView, 95631);
    tagline.text = @"P L A Y   B E Y O N D   L I M I T S";
    tagline.textColor = ZNCyColor(0.34,0.70,1.0,0.95);
    tagline.font = [UIFont systemFontOfSize:6.3 weight:UIFontWeightSemibold];

    UILabel *core = ZNCyLabelWithTag(self.headerView, 95632);
    core.text = @"v0.5.6.2 SEALED CORE  ·  CYBER UI";
    core.textColor = ZNCyColor(0.60,0.73,0.92,0.95);
    core.font = [UIFont systemFontOfSize:8.2 weight:UIFontWeightMedium];
    core.textAlignment = NSTextAlignmentRight;

    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont systemFontOfSize:(self.compactMode ? 14.5 : 16.5) weight:UIFontWeightBold];
    self.subtitleLabel.textColor = ZNCyMuted();
    self.subtitleLabel.font = [UIFont systemFontOfSize:9.2 weight:UIFontWeightRegular];
    self.readyDot.backgroundColor = ZNCyCyan();
    self.readyDot.layer.shadowColor = ZNCyCyan().CGColor;
    self.readyDot.layer.shadowOpacity = 0.9;
    self.readyDot.layer.shadowRadius = 5.0;
    self.readyLabel.textColor = ZNCyColor(0.70,0.96,1.0,1.0);
    self.readyLabel.font = [UIFont systemFontOfSize:8.8 weight:UIFontWeightSemibold];
    self.readyLabel.text = @"READY";

    for (UIButton *b in @[self.themeButton ?: (id)NSNull.null,
                          self.modeButton ?: (id)NSNull.null,
                          self.closeButton ?: (id)NSNull.null]) {
        if ((id)b == (id)NSNull.null) continue;
        ZNCyStyleButton(b, NO);
    }
}

static void ZNCyStyleNavigation(ZNRuntimeMenuControllerV040 *self) {
    NSInteger count = self.sidebarButtons.count;
    for (NSInteger i = 0; i < count; i++) {
        UIButton *b = self.sidebarButtons[i];
        BOOL selected = (i == self.selectedCategory);
        if (i < self.categories.count) [b setTitle:self.categories[i] forState:UIControlStateNormal];
        b.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        b.contentEdgeInsets = UIEdgeInsetsZero;
        b.titleLabel.font = [UIFont systemFontOfSize:10.2 weight:selected ? UIFontWeightBold : UIFontWeightSemibold];
        b.titleLabel.adjustsFontSizeToFitWidth = YES;
        b.titleLabel.minimumScaleFactor = 0.72;
        ZNCyStyleButton(b, selected);
    }
}

@interface ZNRuntimeMenuControllerV040 (ZNCyberpunkRuntimeSkin)
- (void)zncy_makeUI:(UIWindow *)window;
- (void)zncy_applyTheme;
- (void)zncy_layoutPanel;
- (void)zncy_renderPage;
- (void)zncy_updateSidebar;
- (UIView *)zncy_cardAtY:(CGFloat)y height:(CGFloat)h width:(CGFloat)w compact:(BOOL)compact;
- (CGSize)zncy_fullSizeForWindow:(UIWindow *)window;
- (CGSize)zncy_compactSizeForWindow:(UIWindow *)window;
@end

@implementation ZNRuntimeMenuControllerV040 (ZNCyberpunkRuntimeSkin)

- (CGSize)zncy_fullSizeForWindow:(UIWindow *)window {
    (void)[self zncy_fullSizeForWindow:window];
    UIEdgeInsets s = window.safeAreaInsets;
    CGFloat aw = CGRectGetWidth(window.bounds) - s.left - s.right;
    CGFloat ah = CGRectGetHeight(window.bounds) - s.top - s.bottom;
    CGFloat w = MIN(1080.0, MAX(620.0, aw * 0.93));
    CGFloat h = MIN(590.0, MAX(348.0, ah * 0.91));
    w = MIN(w, MAX(280.0, aw - 8.0));
    h = MIN(h, MAX(260.0, ah - 6.0));
    return CGSizeMake(w, h);
}

- (CGSize)zncy_compactSizeForWindow:(UIWindow *)window {
    (void)[self zncy_compactSizeForWindow:window];
    UIEdgeInsets s = window.safeAreaInsets;
    CGFloat aw = CGRectGetWidth(window.bounds) - s.left - s.right;
    CGFloat ah = CGRectGetHeight(window.bounds) - s.top - s.bottom;
    return CGSizeMake(MIN(430.0, MAX(300.0, aw - 12.0)),
                      MIN(330.0, MAX(248.0, ah - 12.0)));
}

- (UIView *)zncy_cardAtY:(CGFloat)y height:(CGFloat)h width:(CGFloat)w compact:(BOOL)compact {
    UIView *card = [self zncy_cardAtY:y height:h width:w compact:compact];
    ZNCyStyleCard(card, compact);
    return card;
}

- (void)zncy_makeUI:(UIWindow *)window {
    [self zncy_makeUI:window];
    ZNCyUpdatePanelLayers(self.panel);
    ZNCyStyleFloatingButton(self.floatButton);
    ZNCyStyleHeader(self);
    ZNCyStyleNavigation(self);
    ZNCyStyleTree(self.contentView);
    [self layoutPanel];
}

- (void)zncy_applyTheme {
    [self zncy_applyTheme];
    ZNCyUpdatePanelLayers(self.panel);
    ZNCyStyleFloatingButton(self.floatButton);
    ZNCyStyleHeader(self);
    ZNCyStyleNavigation(self);
    ZNCyStyleTree(self.panel);
}

- (void)zncy_renderPage {
    [self zncy_renderPage];
    ZNCyStyleTree(self.contentView);
    ZNCyStyleNavigation(self);
}

- (void)zncy_updateSidebar {
    [self zncy_updateSidebar];
    ZNCyStyleNavigation(self);
}

- (void)zncy_layoutPanel {
    [self zncy_layoutPanel];
    if (!self.panel || !self.headerView) return;

    CGFloat w = CGRectGetWidth(self.panel.bounds);
    CGFloat h = CGRectGetHeight(self.panel.bounds);
    ZNCyUpdatePanelLayers(self.panel);
    ZNCyStyleHeader(self);

    UILabel *logo = (UILabel *)[self.headerView viewWithTag:95630];
    UILabel *tagline = (UILabel *)[self.headerView viewWithTag:95631];
    UILabel *core = (UILabel *)[self.headerView viewWithTag:95632];

    if (self.compactMode) {
        self.headerView.frame = CGRectMake(4,4,w-8,54);
        logo.hidden = NO; tagline.hidden = YES; core.hidden = YES;
        logo.frame = CGRectMake(8,6,38,38);
        self.titleLabel.text = @"ZONOE PATCH";
        self.titleLabel.frame = CGRectMake(50,7,MAX(90.0,w-150.0),18);
        self.subtitleLabel.frame = CGRectMake(50,26,MAX(90.0,w-150.0),15);
        self.contentScroll.frame = CGRectMake(8,64,w-16,h-72);
        self.sidebarView.hidden = YES;
        self.footerView.hidden = YES;
        self.contentView.frame = CGRectMake(0,0,CGRectGetWidth(self.contentScroll.bounds),MAX(CGRectGetHeight(self.contentScroll.bounds),self.contentView.frame.size.height));
        ZNCyStyleTree(self.panel);
        [self renderPage];
        return;
    }

    CGFloat headerH = 68.0;
    CGFloat footerH = 19.0;
    NSInteger count = MAX((NSInteger)1, self.sidebarButtons.count);
    NSInteger cols = (w < 560.0 && count > 3) ? 3 : count;
    NSInteger rows = (count + cols - 1) / cols;
    CGFloat navH = rows > 1 ? 78.0 : 48.0;
    CGFloat bodyTop = headerH + 10.0;
    CGFloat bodyBottom = navH + footerH + 12.0;

    self.headerView.frame = CGRectMake(4,4,w-8,headerH-4);
    logo.hidden = NO; tagline.hidden = NO; core.hidden = NO;
    logo.frame = CGRectMake(14,8,42,42);
    self.titleLabel.text = @"ZONOE PATCH";
    self.titleLabel.frame = CGRectMake(64,9,MIN(230.0,MAX(135.0,w*0.32)),20);
    self.subtitleLabel.frame = CGRectMake(64,29,MIN(250.0,MAX(135.0,w*0.34)),15);
    tagline.frame = CGRectMake(64,46,250,10);

    CGFloat right = 12.0;
    self.closeButton.frame = CGRectMake(w-right-36,12,32,32);
    self.modeButton.frame = CGRectMake(CGRectGetMinX(self.closeButton.frame)-39,12,32,32);
    self.themeButton.frame = CGRectMake(CGRectGetMinX(self.modeButton.frame)-39,12,32,32);
    core.frame = CGRectMake(MAX(320.0, CGRectGetMinX(self.themeButton.frame)-185.0),46,
                            MAX(120.0, CGRectGetMinX(self.closeButton.frame)-MAX(320.0, CGRectGetMinX(self.themeButton.frame)-185.0)),12);
    self.readyLabel.frame = CGRectMake(MAX(300.0,CGRectGetMinX(self.themeButton.frame)-66.0),13,46,20);
    self.readyDot.frame = CGRectMake(CGRectGetMinX(self.readyLabel.frame)-11,19,7,7);

    self.contentScroll.frame = CGRectMake(12,bodyTop,w-24,MAX(80.0,h-bodyTop-bodyBottom));
    self.footerView.hidden = NO;
    self.footerView.frame = CGRectMake(14,h-navH-footerH-4,w-28,footerH);
    self.footerView.backgroundColor = UIColor.clearColor;
    self.footerLabel.frame = self.footerView.bounds;
    self.footerLabel.textColor = ZNCyColor(0.43,0.62,0.82,0.92);
    self.footerLabel.font = [UIFont systemFontOfSize:8.0 weight:UIFontWeightMedium];
    self.footerLabel.textAlignment = NSTextAlignmentCenter;

    self.sidebarView.hidden = NO;
    self.sidebarView.frame = CGRectMake(14,h-navH+2,w-28,navH-8);
    self.sidebarView.backgroundColor = UIColor.clearColor;

    CGFloat gap = 8.0;
    CGFloat cellH = rows > 1 ? 29.0 : 36.0;
    CGFloat usableW = CGRectGetWidth(self.sidebarView.bounds) - gap * (cols - 1);
    CGFloat cellW = floor(usableW / cols);
    for (NSInteger i=0; i<self.sidebarButtons.count; i++) {
        NSInteger row = i / cols;
        NSInteger col = i % cols;
        UIButton *b = self.sidebarButtons[i];
        b.frame = CGRectMake(col * (cellW + gap), row * (cellH + 7.0), cellW, cellH);
    }

    self.contentView.frame = CGRectMake(0,0,CGRectGetWidth(self.contentScroll.bounds),MAX(CGRectGetHeight(self.contentScroll.bounds),self.contentView.frame.size.height));
    ZNCyStyleNavigation(self);
    ZNCyStyleTree(self.panel);
    [self renderPage];
}

@end

static void ZNCySwap(Class cls, SEL original, SEL replacement) {
    Method a = class_getInstanceMethod(cls, original);
    Method b = class_getInstanceMethod(cls, replacement);
    if (a && b) method_exchangeImplementations(a, b);
}

extern "C" void ZNCyberpunkUIInstallDeferred(void) {
    @autoreleasepool {
        Class cls = NSClassFromString(@"ZNRuntimeMenuControllerV040");
        if (!cls) return;

        ZNCySwap(cls, @selector(makeUI:), @selector(zncy_makeUI:));
        ZNCySwap(cls, @selector(applyTheme), @selector(zncy_applyTheme));
        ZNCySwap(cls, @selector(layoutPanel), @selector(zncy_layoutPanel));
        ZNCySwap(cls, @selector(renderPage), @selector(zncy_renderPage));
        ZNCySwap(cls, @selector(updateSidebar), @selector(zncy_updateSidebar));
        ZNCySwap(cls, @selector(cardAtY:height:width:compact:), @selector(zncy_cardAtY:height:width:compact:));
        ZNCySwap(cls, @selector(fullSizeForWindow:), @selector(zncy_fullSizeForWindow:));
        ZNCySwap(cls, @selector(compactSizeForWindow:), @selector(zncy_compactSizeForWindow:));

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        NSString *migrationKey = @"zonoe.cyber-ui.v1.full-default-migrated";
        if (![defaults boolForKey:migrationKey]) {
            [defaults setBool:NO forKey:@"ZonoePatch.CompactMode"];
            [defaults setBool:YES forKey:migrationKey];
            if ([cls respondsToSelector:@selector(shared)]) {
                ZNRuntimeMenuControllerV040 *controller = [cls shared];
                controller.compactMode = NO;
            }
        }
    }
}
