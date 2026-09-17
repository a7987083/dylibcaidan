#import "ZNMenuViewController.h"
@class ZNSliderRow;
@interface ZNMenuViewController () <UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>
@property(nonatomic,strong)UIView *panel;
@property(nonatomic,strong)UIView *panelInner;
@property(nonatomic,strong)CAGradientLayer *panelGradient;
@property(nonatomic,strong)UICollectionView *grid;
@property(nonatomic,strong)NSArray<NSString*> *names;
@property(nonatomic,strong)NSArray<NSString*> *assetNames;
@property(nonatomic,strong)ZNSliderRow *speedRow;
@property(nonatomic,strong)ZNSliderRow *fovRow;
@property(nonatomic,assign,getter=isMenuVisible)BOOL menuVisible;
- (void)buildMenu;
- (UIView*)sectionHeader:(NSString*)title symbol:(NSString*)symbol;
- (UIButton*)tabButton:(NSString*)title symbol:(NSString*)symbol tag:(NSInteger)tag selected:(BOOL)selected;
- (void)switchChanged:(id)sender;
- (void)sliderChanged:(UISlider*)slider;
- (void)tabTapped:(UIButton*)button;
@end
