#import <UIKit/UIKit.h>
#import "ZNOverlay.h"
#import "ZNCompactLayoutFix.h"

@interface ZNBootstrap : NSObject
+ (void)install;
@end

@implementation ZNBootstrap
+ (void)install {
    ZNInstallCompactLayoutFix();
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
        [[ZNOverlayManager shared] start];
    }];
    [center addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
        [[ZNOverlayManager shared] start];
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (UIApplication.sharedApplication.connectedScenes.count > 0 || UIApplication.sharedApplication.windows.count > 0) {
            [[ZNOverlayManager shared] start];
        }
    });
}
@end

__attribute__((constructor))
static void ZNDylibEntry(void) {
    @autoreleasepool {
        [ZNBootstrap install];
    }
}
