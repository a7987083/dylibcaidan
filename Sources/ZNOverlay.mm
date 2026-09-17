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
    self.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.90 blue:1.0 alpha:1.0].CGColor;
    self.layer.shadowOpacity = 0.62;
    self.layer.shadowRadius = 13.0;
    self.layer.shadowOffset = CGSizeZero;

    _gradientLayer = [CAGradientLayer layer];
    _gradientLayer.colors = @[(id)[UIColor colorWithRed:0.0 green:0.91 blue:1.0 alpha:1.0].CGColor,
                              (id)[UIColor colorWithRed:0.95 green:0.08 blue:0.96 alpha:1.0].CGColor];
    _gradientLayer.startPoint = CGPointMake(0, 0);
    _gradientLayer.endPoint = CGPointMake(1, 1);
    [self.layer addSublayer:_gradientLayer];

    UIView *inner = [[UIView alloc] initWithFrame:CGRectZero];
    inner.translatesAutoresizingMaskIntoConstraints = NO;
    inner.userInteractionEnabled = NO;
    inner.backgroundColor = [UIColor colorWithRed:0.01 green:0.025 blue:0.065 alpha:0.95];
    inner.layer.cornerRadius = MAX(0, frame.size.width * 0.5 - 3);
    inner.layer.borderWidth = 1.0;
    inner.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
    [self addSubview:inner];

    UILabel *glyph = [[UILabel alloc] initWithFrame:CGRectZero];
    glyph.translatesAutoresizingMaskIntoConstraints = NO;
    glyph.text = @"N";
    glyph.textAlignment = NSTextAlignmentCenter;
    glyph.textColor = UIColor.whiteColor;
    glyph.font = [UIFont italicSystemFontOfSize:22.0];
    glyph.layer.shadowColor = UIColor.cyanColor.CGColor;
    glyph.layer.shadowOpacity = 0.8;
    glyph.layer.shadowRadius = 5.0;
    glyph.layer.shadowOffset = CGSizeZero;
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

- (void)handleTap {
    if (self.tapHandler) self.tapHandler();
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    UIView *container = self.superview;
    if (!container) return;
    if (pan.state == UIGestureRecognizerStateBegan) self.panOrigin = self.center;
    CGPoint translation = [pan translationInView:container];
    CGPoint center = CGPointMake(self.panOrigin.x + translation.x, self.panOrigin.y + translation.y);
    UIEdgeInsets safe = container.safeAreaInsets;
    CGFloat halfWidth = CGRectGetWidth(self.bounds) * 0.5;
    CGFloat halfHeight = CGRectGetHeight(self.bounds) * 0.5;
    center.x = MIN(MAX(center.x, safe.left + halfWidth + 6), CGRectGetWidth(container.bounds) - safe.right - halfWidth - 6);
    center.y = MIN(MAX(center.y, safe.top + halfHeight + 6), CGRectGetHeight(container.bounds) - safe.bottom - halfHeight - 6);
    self.center = center;
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

    self.floatingButton = [[ZNFloatingButton alloc] initWithFrame:CGRectMake(18, 96, 56, 56)];
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
    CGRect frame = self.floatingButton.frame;
    frame.origin.x = MIN(MAX(frame.origin.x, safe.left + 6), CGRectGetWidth(self.view.bounds) - safe.right - CGRectGetWidth(frame) - 6);
    frame.origin.y = MIN(MAX(frame.origin.y, safe.top + 6), CGRectGetHeight(self.view.bounds) - safe.bottom - CGRectGetHeight(frame) - 6);
    self.floatingButton.frame = frame;
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
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        if (!fallback) fallback = windowScene;
        if (windowScene.activationState == UISceneActivationStateForegroundActive) return windowScene;
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
