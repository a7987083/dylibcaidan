#import "ZNOverlay.h"
#import "ZNMenuViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation ZNOverlayWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (!hit || hit == self.rootViewController.view) ? nil : hit;
}
@end

@interface ZNFloatingButton ()
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) CGPoint panOrigin;
@end

@implementation ZNFloatingButton
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.layer.cornerRadius = frame.size.width * 0.5;
    self.layer.shadowColor = UIColor.cyanColor.CGColor;
    self.layer.shadowOpacity = 0.55;
    self.layer.shadowRadius = 12.0;
    self.layer.shadowOffset = CGSizeZero;

    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.colors = @[(id)[UIColor colorWithRed:0.02 green:0.72 blue:1 alpha:1].CGColor,
                              (id)[UIColor colorWithRed:0.68 green:0.12 blue:1 alpha:1].CGColor];
    _gradientLayer.startPoint = CGPointMake(0,0);
    _gradientLayer.endPoint = CGPointMake(1,1);
    [self.layer addSublayer:_gradientLayer];

    UIView *inner = [[UIView alloc] initWithFrame:CGRectZero];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    inner.userInteractionEnabled = NO;
    inner.backgroundColor = [UIColor colorWithRed:0.015 green:0.035 blue:0.08 alpha:0.92];
    inner.layer.cornerRadius = MAX(0, frame.size.width * 0.5 - 3);
    inner.layer.borderWidth = 1;
    inner.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    [self addSubview:inner];

    UILabel *glyph = [[UILabel alloc] initWithFrame:CGRectZero];
    glyph.translatesAutoresizingMaskIntoConstraints = NO;
    glyph.text = @"X";
    glyph.textAlignment = NSTextAlignmentCenter;
    glyph.textColor = UIColor.whiteColor;
    glyph.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBlack];
    [inner addSubview:glyph];

    [NSLayoutConstraint activateConstraints:@[
        [inner.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3],
        [inner.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-3],
        [inner.topAnchor constraintEqualToAnchor:self.topAnchor constant:3],
        [inner.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-3],
        [glyph.centerXAnchor constraintEqualToAnchor:inner.centerXAnchor],
        [glyph.centerYAnchor constraintEqualToAnchor:inner.centerYAnchor]
    ]];

    [self addTarget:self action:@selector(handleTap) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.cancelsTouchesInView = YES;
    [self addGestureRecognizer:pan];
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
    self.gradientLayer.cornerRadius = self.bounds.size.width * 0.5;
}
- (void)handleTap { if (self.tapHandler) self.tapHandler(); }
- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *container = self.superview;
    if (!container) return;
    if (pan.state == UIGestureRecognizerStateBegan) self.panOrigin = self.center;
    CGPoint t = [pan translationInView:container];
    CGPoint c = CGPointMake(self.panOrigin.x + t.x, self.panOrigin.y + t.y);
    UIEdgeInsets safe = container.safeAreaInsets;
    CGFloat hw = CGRectGetWidth(self.bounds)/2.0, hh = CGRectGetHeight(self.bounds)/2.0;
    c.x = MIN(MAX(c.x, safe.left + hw + 6), CGRectGetWidth(container.bounds) - safe.right - hw - 6);
    c.y = MIN(MAX(c.y, safe.top + hh + 6), CGRectGetHeight(container.bounds) - safe.bottom - hh - 6);
    self.center = c;
}
@end

@interface ZNOverlayRootController : UIViewController
@property (nonatomic, strong) ZNMenuViewController *menuController;
@property (nonatomic, strong) ZNFloatingButton *floatingButton;
@end

@implementation ZNOverlayRootController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    self.menuController = [[ZNMenuViewController alloc] init];
    [self addChildViewController:self.menuController];
    self.menuController.view.frame = self.view.bounds;
    self.menuController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.menuController.view];
    [self.menuController didMoveToParentViewController:self];

    self.floatingButton = [[ZNFloatingButton alloc] initWithFrame:CGRectMake(18, 96, 54, 54)];
    [self.view addSubview:self.floatingButton];
    __weak ZNOverlayRootController *weakSelf = self;
    self.floatingButton.tapHandler = ^{
        [weakSelf.menuController toggleMenu];
        [weakSelf.view bringSubviewToFront:weakSelf.floatingButton];
    };
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGRect f = self.floatingButton.frame;
    f.origin.x = MIN(MAX(f.origin.x, safe.left + 6), CGRectGetWidth(self.view.bounds) - safe.right - CGRectGetWidth(f) - 6);
    f.origin.y = MIN(MAX(f.origin.y, safe.top + 6), CGRectGetHeight(self.view.bounds) - safe.bottom - CGRectGetHeight(f) - 6);
    self.floatingButton.frame = f;
    [self.view bringSubviewToFront:self.floatingButton];
}
- (BOOL)shouldAutorotate { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }
@end

@interface ZNOverlayManager ()
@property (nonatomic, strong) ZNOverlayWindow *window;
@property (nonatomic, assign) BOOL started;
@end

@implementation ZNOverlayManager
+ (instancetype)shared {
    static ZNOverlayManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [[ZNOverlayManager alloc] init]; });
    return manager;
}
- (UIWindowScene *)foregroundWindowScene API_AVAILABLE(ios(13.0)) {
    UIWindowScene *fallback = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        if (!fallback) fallback = ws;
        if (ws.activationState == UISceneActivationStateForegroundActive) return ws;
    }
    return fallback;
}
- (void)start {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.started && self.window) return;
        ZNOverlayWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            UIWindowScene *scene = [self foregroundWindowScene];
            if (!scene) return;
            window = [[ZNOverlayWindow alloc] initWithWindowScene:scene];
        } else {
            window = [[ZNOverlayWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        }
        window.backgroundColor = UIColor.clearColor;
        window.windowLevel = UIWindowLevelAlert + 88.0;
        window.rootViewController = [[ZNOverlayRootController alloc] init];
        window.hidden = NO;
        self.window = window;
        self.started = YES;
    });
}
@end
