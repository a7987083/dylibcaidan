#import "ZNMenuPrivate.h"
#import "ZNUIComponents.h"
#import "ZNEmbeddedAssets.h"
#import <QuartzCore/QuartzCore.h>
NSNotificationName const ZNMenuValueChangedNotification=@"ZNMenuValueChangedNotification";
@implementation ZNMenuViewController
-(void)viewDidLoad{[super viewDidLoad];self.view.backgroundColor=UIColor.clearColor;self.names=@[@"Sunset Glow",@"Cyberpunk Vibe",@"Noir Classic",@"Film Grain",@"Lomo Retro",@"Vibrant Day",@"Liquid Art",@"Glitch Effect",@"Vintage Portrait",@"Space Nebula",@"City Nights",@"Minimal Art"];self.assetNames=@[@"sunset",@"cyberpunk",@"noir",@"film",@"lomo",@"vibrant",@"liquid",@"glitch",@"vintage",@"nebula",@"city",@"minimal"];[self buildMenu];[self setMenuVisible:NO animated:NO];}
-(void)viewDidLayoutSubviews{[super viewDidLayoutSubviews];CGRect b=self.view.bounds;UIEdgeInsets s=self.view.safeAreaInsets;CGFloat aw=CGRectGetWidth(b)-s.left-s.right,ah=CGRectGetHeight(b)-s.top-s.bottom;CGFloat w=MIN(1120,MAX(690,aw*.93)),h=MIN(585,MAX(350,ah*.89));w=MIN(w,aw-10);h=MIN(h,ah-6);self.panel.frame=CGRectIntegral(CGRectMake(s.left+(aw-w)/2,s.top+(ah-h)/2,w,h));self.panelGradient.frame=self.panel.bounds;[self.grid.collectionViewLayout invalidateLayout];}
-(void)switchChanged:(ZNNeonSwitch*)sender{NSString*k=sender.accessibilityIdentifier?:@"toggle";[[NSNotificationCenter defaultCenter]postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":k,@"value":@(sender.on)}];}
-(void)sliderChanged:(UISlider*)s{if([s.accessibilityIdentifier isEqualToString:@"walk_speed"])self.speedRow.valueLabel.text=[NSString stringWithFormat:@"%.1fx",.5+s.value];else if([s.accessibilityIdentifier isEqualToString:@"fov"])self.fovRow.valueLabel.text=[NSString stringWithFormat:@"%.0f°",45+s.value*52];[[NSNotificationCenter defaultCenter]postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":s.accessibilityIdentifier?:@"slider",@"value":@(s.value)}];}
-(void)tabTapped:(UIButton*)b{[[NSNotificationCenter defaultCenter]postNotificationName:ZNMenuValueChangedNotification object:self userInfo:@{@"key":@"tab",@"value":@(b.tag)}];}
-(void)toggleMenu{[self setMenuVisible:!self.menuVisible animated:YES];}
-(void)setMenuVisible:(BOOL)v animated:(BOOL)a{self.menuVisible=v;void(^c)(void)=^{self.panel.alpha=v?1:0;self.panel.transform=v?CGAffineTransformIdentity:CGAffineTransformMakeScale(.965,.965);};if(!a){c();self.panel.hidden=!v;return;}if(v)self.panel.hidden=NO;[UIView animateWithDuration:.2 delay:0 options:UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionBeginFromCurrentState animations:c completion:^(__unused BOOL f){if(!v)self.panel.hidden=YES;}];}
-(NSInteger)collectionView:(UICollectionView*)c numberOfItemsInSection:(NSInteger)s{return self.names.count;}
-(__kindof UICollectionViewCell*)collectionView:(UICollectionView*)c cellForItemAtIndexPath:(NSIndexPath*)p{ZNPresetCell*x=[c dequeueReusableCellWithReuseIdentifier:@"preset" forIndexPath:p];x.imageView.image=ZNEmbeddedImage(self.assetNames[p.item]);x.caption.text=[NSString stringWithFormat:@"[%@]",self.names[p.item]];return x;}
-(CGSize)collectionView:(UICollectionView*)c layout:(UICollectionViewLayout*)l sizeForItemAtIndexPath:(NSIndexPath*)p{CGFloat w=floor((CGRectGetWidth(c.bounds)-24)/4.0);CGFloat h=floor((MAX(120,CGRectGetHeight(c.bounds))-16)/3.0);return CGSizeMake(MAX(72,w),MAX(60,h));}
@end
