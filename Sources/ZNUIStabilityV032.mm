#import "ZNUIStabilityV032.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

__attribute__((used)) static const char kZNUIStabilityMarker[] = "ZN_UI_STABILITY_V032";

static void (*ZNOriginalMenuViewDidLoad)(id, SEL) = nullptr;
static void (*ZNOriginalMenuViewDidLayout)(id, SEL) = nullptr;
static UIView *(*ZNOriginalOverlayHitTest)(id, SEL, CGPoint, UIEvent *) = nullptr;
static char kZNPickerScrollKey;

static inline CGFloat ZNClamp(CGFloat v, CGFloat lo, CGFloat hi) {
    return MIN(MAX(v, lo), hi);
}

static UIView *ZNV(id object, NSString *key) {
    id value = nil;
    @try { value = [object valueForKey:key]; } @catch (__unused NSException *e) { return nil; }
    return [value isKindOfClass:UIView.class] ? value : nil;
}

static NSArray<UIView *> *ZNViews(id object, NSString *key) {
    id value = nil;
    @try { value = [object valueForKey:key]; } @catch (__unused NSException *e) { return @[]; }
    if (![value isKindOfClass:NSArray.class]) return @[];
    NSMutableArray<UIView *> *views = [NSMutableArray array];
    for (id item in (NSArray *)value) if ([item isKindOfClass:UIView.class]) [views addObject:item];
    return views;
}

static NSInteger ZNLayoutIndex(id controller) {
    id value = nil;
    @try { value = [controller valueForKey:@"selectedLayoutIndex"]; } @catch (__unused NSException *e) { return 0; }
    return [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : 0;
}

static void ZNLayoutHeader(id controller) {
    UIVisualEffectView *blur = (UIVisualEffectView *)ZNV(controller, @"blur");
    UIView *logo = ZNV(controller, @"logoView");
    UILabel *title = (UILabel *)ZNV(controller, @"titleLabel");
    UILabel *subtitle = (UILabel *)ZNV(controller, @"subtitleLabel");
    UIView *status = ZNV(controller, @"statusTag");
    UIButton *layout = (UIButton *)ZNV(controller, @"layoutButton");
    if (!blur || !logo || !title || !subtitle || !status || !layout) return;

    CGRect b = blur.contentView.bounds;
    if (b.size.width >= 620.0) return;

    CGFloat rightPad = 12.0;
    CGFloat statusW = 74.0;
    CGFloat statusX = MAX(240.0, b.size.width - rightPad - statusW);
    logo.frame = CGRectIntegral(CGRectMake(14, 8, 36, 36));
    title.frame = CGRectIntegral(CGRectMake(58, 5, MAX(120.0, statusX - 64.0), 21));
    status.frame = CGRectIntegral(CGRectMake(statusX, 9, statusW, 25));

    CGFloat subtitleW = MIN(104.0, MAX(76.0, b.size.width * 0.27));
    subtitle.frame = CGRectIntegral(CGRectMake(58, 27, subtitleW, 15));
    CGFloat layoutX = CGRectGetMaxX(subtitle.frame) + 5.0;
    CGFloat layoutW = MAX(88.0, statusX - layoutX - 7.0);
    if (layoutW < 96.0) {
        subtitle.frame = CGRectMake(58, 27, 72, 15);
        layoutX = CGRectGetMaxX(subtitle.frame) + 4.0;
        layoutW = MAX(88.0, statusX - layoutX - 7.0);
    }
    layout.frame = CGRectIntegral(CGRectMake(layoutX, 25, layoutW, 26));
    layout.titleLabel.font = [UIFont systemFontOfSize:9.4 weight:UIFontWeightSemibold];
}

static void ZNLayoutNavContents(id controller) {
    UIView *card = ZNV(controller, @"navCard");
    UILabel *title = (UILabel *)ZNV(controller, @"navTitle");
    UILabel *scope = (UILabel *)ZNV(controller, @"scopeLabel");
    NSArray<UIView *> *buttons = ZNViews(controller, @"navButtons");
    if (!card || !title || !scope || buttons.count < 4) return;

    CGRect b = card.bounds;
    CGFloat w = b.size.width, h = b.size.height, pad = 8.0;
    NSInteger variant = ZNLayoutIndex(controller);
    title.hidden = NO;
    scope.hidden = NO;
    scope.numberOfLines = 2;

    BOOL strip = (h <= 76.0 && w >= 250.0);
    BOOL grid = !strip && w >= 145.0 && h < 210.0 && ((variant % 4) == 1 || h < 145.0);
    BOOL vertical = !strip && !grid && (w < 165.0 || h >= 210.0);

    if (strip) {
        CGFloat titleW = MIN(56.0, w * 0.16);
        CGFloat scopeW = MIN(92.0, w * 0.24);
        title.frame = CGRectIntegral(CGRectMake(pad, 7, titleW, 18));
        CGFloat x = CGRectGetMaxX(title.frame) + 5.0;
        CGFloat available = MAX(132.0, w - x - scopeW - 2.0 * pad - 5.0);
        CGFloat bw = MAX(28.0, (available - 15.0) / 4.0);
        CGFloat bh = MAX(30.0, h - 14.0);
        for (NSInteger i = 0; i < 4; i++) buttons[i].frame = CGRectIntegral(CGRectMake(x + i * (bw + 5.0), 7, bw, bh));
        scope.frame = CGRectIntegral(CGRectMake(w - scopeW - pad, 7, scopeW, bh));
        scope.textAlignment = NSTextAlignmentRight;
    } else if (grid) {
        title.frame = CGRectIntegral(CGRectMake(pad, 7, w - 2.0 * pad, 17));
        CGFloat scopeH = 22.0;
        CGFloat top = 28.0;
        CGFloat bottom = scopeH + 8.0;
        CGFloat gap = 5.0;
        CGFloat cellW = MAX(44.0, (w - 2.0 * pad - gap) / 2.0);
        CGFloat cellH = MAX(26.0, MIN(38.0, (h - top - bottom - gap) / 2.0));
        for (NSInteger i = 0; i < 4; i++) {
            NSInteger r = i / 2, c = i % 2;
            buttons[i].frame = CGRectIntegral(CGRectMake(pad + c * (cellW + gap), top + r * (cellH + gap), cellW, cellH));
        }
        scope.frame = CGRectIntegral(CGRectMake(pad, h - scopeH - 5.0, w - 2.0 * pad, scopeH));
        scope.textAlignment = NSTextAlignmentLeft;
    } else if (vertical) {
        title.frame = CGRectIntegral(CGRectMake(pad, 7, w - 2.0 * pad, 17));
        CGFloat top = 29.0, scopeH = 27.0, gap = 4.0;
        CGFloat available = MAX(112.0, h - top - scopeH - 9.0);
        CGFloat bh = MAX(26.0, MIN(38.0, (available - 3.0 * gap) / 4.0));
        for (NSInteger i = 0; i < 4; i++) buttons[i].frame = CGRectIntegral(CGRectMake(pad, top + i * (bh + gap), MAX(44.0, w - 2.0 * pad), bh));
        scope.frame = CGRectIntegral(CGRectMake(pad, h - scopeH - 5.0, w - 2.0 * pad, scopeH));
        scope.textAlignment = NSTextAlignmentLeft;
    } else {
        title.frame = CGRectIntegral(CGRectMake(pad, 7, w - 2.0 * pad, 17));
        CGFloat top = 29.0, gap = 5.0;
        CGFloat bw = MAX(32.0, (w - 2.0 * pad - 3.0 * gap) / 4.0);
        for (NSInteger i = 0; i < 4; i++) buttons[i].frame = CGRectIntegral(CGRectMake(pad + i * (bw + gap), top, bw, 32.0));
        scope.frame = CGRectIntegral(CGRectMake(pad, MIN(h - 24.0, 66.0), w - 2.0 * pad, 20.0));
        scope.textAlignment = NSTextAlignmentLeft;
    }
}

static void ZNLayoutEditorContents(id controller) {
    UIView *card = ZNV(controller, @"editorCard");
    UILabel *editorTitle = (UILabel *)ZNV(controller, @"editorTitle");
    UILabel *addressCaption = (UILabel *)ZNV(controller, @"addressCaption");
    UILabel *valueCaption = (UILabel *)ZNV(controller, @"valueCaption");
    UITextField *addressField = (UITextField *)ZNV(controller, @"addressField");
    UITextField *valueField = (UITextField *)ZNV(controller, @"valueField");
    UIView *typeControl = ZNV(controller, @"typeControl");
    UIButton *readButton = (UIButton *)ZNV(controller, @"readButton");
    UIButton *writeButton = (UIButton *)ZNV(controller, @"writeButton");
    UIButton *freezeButton = (UIButton *)ZNV(controller, @"freezeButton");
    UIButton *clearButton = (UIButton *)ZNV(controller, @"clearButton");
    UILabel *resolved = (UILabel *)ZNV(controller, @"resolvedLabel");
    UITextView *log = (UITextView *)ZNV(controller, @"logView");
    if (!card || !editorTitle || !addressCaption || !valueCaption || !addressField || !valueField || !typeControl || !readButton || !writeButton || !freezeButton || !clearButton || !resolved || !log) return;

    CGFloat w = card.bounds.size.width, h = card.bounds.size.height;
    CGFloat pad = ZNClamp(w * 0.035, 7.0, 11.0);
    NSInteger variant = ZNLayoutIndex(controller);
    BOOL splitFields = (w >= 285.0 && (h < 250.0 || variant == 6 || variant == 10 || variant == 19));
    BOOL narrow = (w < 230.0);

    editorTitle.frame = CGRectIntegral(CGRectMake(pad, 7, MAX(80.0, w - 2.0 * pad), 17));

    if (splitFields) {
        CGFloat gap = 7.0;
        CGFloat half = MAX(90.0, (w - 2.0 * pad - gap) / 2.0);
        addressCaption.frame = CGRectIntegral(CGRectMake(pad, 28, half, 12));
        valueCaption.frame = CGRectIntegral(CGRectMake(pad + half + gap, 28, half, 12));
        addressField.frame = CGRectIntegral(CGRectMake(pad, 41, half, 29));
        valueField.frame = CGRectIntegral(CGRectMake(pad + half + gap, 41, half, 29));
        typeControl.frame = CGRectIntegral(CGRectMake(pad, 76, w - 2.0 * pad, 27));
        CGFloat bw = MAX(44.0, (w - 2.0 * pad - 18.0) / 4.0);
        CGFloat by = 109.0;
        readButton.frame = CGRectIntegral(CGRectMake(pad, by, bw, 31));
        writeButton.frame = CGRectIntegral(CGRectMake(pad + bw + 6, by, bw, 31));
        freezeButton.frame = CGRectIntegral(CGRectMake(pad + 2 * (bw + 6), by, bw, 31));
        clearButton.frame = CGRectIntegral(CGRectMake(pad + 3 * (bw + 6), by, MAX(40.0, w - pad - (pad + 3 * (bw + 6))), 31));
        resolved.frame = CGRectIntegral(CGRectMake(pad, 144, w - 2.0 * pad, 14));
        log.frame = CGRectIntegral(CGRectMake(pad, 161, w - 2.0 * pad, MAX(28.0, h - 168.0)));
        return;
    }

    CGFloat scale = ZNClamp(h / 315.0, 0.72, 1.0);
    CGFloat fieldH = 30.0 * scale, segH = 27.0 * scale, buttonH = 31.0 * scale;
    CGFloat gap = 4.0 * scale, y = 28.0;
    addressCaption.frame = CGRectIntegral(CGRectMake(pad, y, w - 2.0 * pad, 12)); y += 14.0;
    addressField.frame = CGRectIntegral(CGRectMake(pad, y, w - 2.0 * pad, fieldH)); y += fieldH + gap;
    valueCaption.frame = CGRectIntegral(CGRectMake(pad, y, w - 2.0 * pad, 12)); y += 14.0;
    valueField.frame = CGRectIntegral(CGRectMake(pad, y, w - 2.0 * pad, fieldH)); y += fieldH + gap;
    typeControl.frame = CGRectIntegral(CGRectMake(pad, y, w - 2.0 * pad, segH)); y += segH + gap;

    if (narrow) {
        CGFloat cellGap = 5.0;
        CGFloat bw = MAX(48.0, (w - 2.0 * pad - cellGap) / 2.0);
        readButton.frame = CGRectIntegral(CGRectMake(pad, y, bw, buttonH));
        writeButton.frame = CGRectIntegral(CGRectMake(pad + bw + cellGap, y, bw, buttonH));
        y += buttonH + cellGap;
        freezeButton.frame = CGRectIntegral(CGRectMake(pad, y, bw, buttonH));
        clearButton.frame = CGRectIntegral(CGRectMake(pad + bw + cellGap, y, bw, buttonH));
        y += buttonH + 4.0;
    } else {
        CGFloat bw = MAX(42.0, (w - 2.0 * pad - 18.0) / 4.0);
        readButton.frame = CGRectIntegral(CGRectMake(pad, y, bw, buttonH));
        writeButton.frame = CGRectIntegral(CGRectMake(pad + bw + 6, y, bw, buttonH));
        freezeButton.frame = CGRectIntegral(CGRectMake(pad + 2 * (bw + 6), y, bw, buttonH));
        clearButton.frame = CGRectIntegral(CGRectMake(pad + 3 * (bw + 6), y, MAX(40.0, w - pad - (pad + 3 * (bw + 6))), buttonH));
        y += buttonH + 4.0;
    }

    resolved.frame = CGRectIntegral(CGRectMake(pad, y, w - 2.0 * pad, 14)); y += 17.0;
    log.frame = CGRectIntegral(CGRectMake(pad, y, w - 2.0 * pad, MAX(26.0, h - y - pad)));
}

static void ZNLayoutInspectorContents(id controller) {
    UIView *card = ZNV(controller, @"inspectorCard");
    UILabel *title = (UILabel *)ZNV(controller, @"inspectorTitle");
    UILabel *hint = (UILabel *)ZNV(controller, @"inspectorHint");
    UITextView *text = (UITextView *)ZNV(controller, @"inspectorView");
    if (!card || !title || !hint || !text) return;
    CGFloat w = card.bounds.size.width, h = card.bounds.size.height, pad = 8.0;
    if (h < 92.0 && w >= 190.0) {
        title.frame = CGRectIntegral(CGRectMake(pad, 7, w * 0.43, 17));
        hint.frame = CGRectIntegral(CGRectMake(w * 0.44, 7, w * 0.56 - pad, 17));
        hint.textAlignment = NSTextAlignmentRight;
        text.frame = CGRectIntegral(CGRectMake(pad, 28, w - 2.0 * pad, MAX(28.0, h - 35.0)));
    } else {
        title.frame = CGRectIntegral(CGRectMake(pad, 7, w - 2.0 * pad, 17));
        hint.frame = CGRectIntegral(CGRectMake(pad, 25, w - 2.0 * pad, 14));
        hint.textAlignment = NSTextAlignmentLeft;
        text.frame = CGRectIntegral(CGRectMake(pad, 42, w - 2.0 * pad, MAX(28.0, h - 49.0)));
    }
}

static UIScrollView *ZNPickerScroll(id controller) {
    UIView *pickerCard = ZNV(controller, @"pickerCard");
    if (!pickerCard) return nil;
    return objc_getAssociatedObject(pickerCard, &kZNPickerScrollKey);
}

static void ZNInstallPickerScroll(id controller) {
    UIView *pickerCard = ZNV(controller, @"pickerCard");
    if (!pickerCard || ZNPickerScroll(controller)) return;
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    scroll.backgroundColor = UIColor.clearColor;
    scroll.showsVerticalScrollIndicator = YES;
    scroll.alwaysBounceVertical = YES;
    scroll.directionalLockEnabled = YES;
    scroll.clipsToBounds = YES;
    scroll.accessibilityIdentifier = @"ZNLayoutPickerScrollV032";
    [pickerCard addSubview:scroll];
    for (UIView *button in ZNViews(controller, @"pickerButtons")) [scroll addSubview:button];
    objc_setAssociatedObject(pickerCard, &kZNPickerScrollKey, scroll, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void ZNLayoutPicker(id controller) {
    UIView *pickerCard = ZNV(controller, @"pickerCard");
    UILabel *title = (UILabel *)ZNV(controller, @"pickerTitle");
    UIButton *close = (UIButton *)ZNV(controller, @"pickerCloseButton");
    UIScrollView *scroll = ZNPickerScroll(controller);
    NSArray<UIView *> *buttons = ZNViews(controller, @"pickerButtons");
    if (!pickerCard || !title || !close || !scroll || buttons.count < 20) return;

    CGRect p = pickerCard.bounds;
    title.frame = CGRectIntegral(CGRectMake(14, 9, MAX(120.0, p.size.width - 110.0), 24));
    close.frame = CGRectIntegral(CGRectMake(MAX(14.0, p.size.width - 82.0), 8, 68, 28));
    scroll.frame = CGRectIntegral(CGRectMake(10, 43, MAX(120.0, p.size.width - 20.0), MAX(80.0, p.size.height - 53.0)));

    NSInteger cols = p.size.width >= 620.0 ? 4 : 2;
    CGFloat gap = 7.0, pad = 3.0, itemH = 38.0;
    CGFloat bw = MAX(92.0, (scroll.bounds.size.width - 2.0 * pad - (cols - 1) * gap) / cols);
    NSInteger rows = (20 + cols - 1) / cols;
    for (NSInteger idx = 0; idx < 20; idx++) {
        NSInteger r = idx / cols, c = idx % cols;
        buttons[idx].frame = CGRectIntegral(CGRectMake(pad + c * (bw + gap), pad + r * (itemH + gap), bw, itemH));
    }
    CGFloat contentH = 2.0 * pad + rows * itemH + MAX(0, rows - 1) * gap;
    scroll.contentSize = CGSizeMake(scroll.bounds.size.width, contentH);
}

static void ZNPatchedMenuViewDidLoad(id self, SEL _cmd) {
    if (ZNOriginalMenuViewDidLoad) ZNOriginalMenuViewDidLoad(self, _cmd);
    ZNInstallPickerScroll(self);
}

static void ZNPatchedMenuViewDidLayout(id self, SEL _cmd) {
    if (ZNOriginalMenuViewDidLayout) ZNOriginalMenuViewDidLayout(self, _cmd);
    ZNLayoutHeader(self);
    ZNLayoutNavContents(self);
    ZNLayoutEditorContents(self);
    ZNLayoutInspectorContents(self);
    ZNLayoutPicker(self);
}

static UIView *ZNPatchedOverlayHitTest(id self, SEL _cmd, CGPoint point, UIEvent *event) {
    UIView *hit = ZNOriginalOverlayHitTest ? ZNOriginalOverlayHitTest(self, _cmd, point, event) : nil;
    if (!hit) return nil;

    UIWindow *window = (UIWindow *)self;
    UIViewController *root = window.rootViewController;
    UIView *floating = ZNV(root, @"floatingButton");
    id menuController = nil;
    @try { menuController = [root valueForKey:@"menuController"]; } @catch (__unused NSException *e) {}
    UIView *panel = menuController ? ZNV(menuController, @"panel") : nil;

    if (floating && (hit == floating || [hit isDescendantOfView:floating])) return hit;
    if (panel && !panel.hidden && panel.alpha > 0.02 && (hit == panel || [hit isDescendantOfView:panel])) return hit;
    return nil;
}

static BOOL ZNSwizzleInstanceMethod(Class cls, SEL selector, IMP replacement, IMP *originalOut) {
    if (!cls || !selector || !replacement || !originalOut) return NO;
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return NO;
    *originalOut = method_getImplementation(method);
    method_setImplementation(method, replacement);
    return YES;
}

void ZNInstallUIStabilityV032(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class menuClass = NSClassFromString(@"ZNMenuViewController");
        Class overlayClass = NSClassFromString(@"ZNOverlayWindow");
        ZNSwizzleInstanceMethod(menuClass, @selector(viewDidLoad), (IMP)ZNPatchedMenuViewDidLoad, (IMP *)&ZNOriginalMenuViewDidLoad);
        ZNSwizzleInstanceMethod(menuClass, @selector(viewDidLayoutSubviews), (IMP)ZNPatchedMenuViewDidLayout, (IMP *)&ZNOriginalMenuViewDidLayout);
        ZNSwizzleInstanceMethod(overlayClass, @selector(hitTest:withEvent:), (IMP)ZNPatchedOverlayHitTest, (IMP *)&ZNOriginalOverlayHitTest);
    });
}
