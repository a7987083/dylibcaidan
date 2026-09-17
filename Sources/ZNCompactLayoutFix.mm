#import "ZNCompactLayoutFix.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

__attribute__((used)) static const char kZNCompactLayoutMarker[] = "ZN_COMPACT_LAYOUT_V4_20_DISTINCT_PORTRAIT";

static void (*ZNOriginalViewDidLayoutSubviews)(id, SEL) = nullptr;

static inline CGFloat ZNClamp(CGFloat v, CGFloat lo, CGFloat hi) {
    return MIN(MAX(v, lo), hi);
}

static void ZNRelayoutCardContents(id controller) {
    SEL navSel = NSSelectorFromString(@"layoutNavContents");
    SEL editSel = NSSelectorFromString(@"layoutEditorContents");
    SEL inspSel = NSSelectorFromString(@"layoutInspectorContents");
    if ([controller respondsToSelector:navSel]) ((void(*)(id,SEL))objc_msgSend)(controller, navSel);
    if ([controller respondsToSelector:editSel]) ((void(*)(id,SEL))objc_msgSend)(controller, editSel);
    if ([controller respondsToSelector:inspSel]) ((void(*)(id,SEL))objc_msgSend)(controller, inspSel);
}

static void ZNSetFrames(UIView *nav, UIView *editor, UIView *inspector, CGRect n, CGRect e, CGRect i) {
    nav.frame = CGRectIntegral(n);
    editor.frame = CGRectIntegral(e);
    inspector.frame = CGRectIntegral(i);
}

static void ZNApplyCompactLayout(id controller, CGRect a, NSInteger index) {
    UIView *nav = [controller valueForKey:@"navCard"];
    UIView *editor = [controller valueForKey:@"editorCard"];
    UIView *inspector = [controller valueForKey:@"inspectorCard"];
    if (!nav || !editor || !inspector) return;

    CGFloat x=a.origin.x, y=a.origin.y, w=a.size.width, h=a.size.height;
    CGFloat g=7.0;
    CGFloat navH=ZNClamp(h*0.14, 48, 60);
    CGFloat inspH=ZNClamp(h*0.25, 82, 118);
    CGFloat rail=ZNClamp(w*0.27, 88, 108);
    CGFloat inspRail=ZNClamp(w*0.31, 96, 122);
    CGRect n=CGRectZero,e=CGRectZero,i=CGRectZero;

    switch (MAX(0, MIN(19, index))) {
        case 0: { // 经典三栏：上/中/下
            n=CGRectMake(x,y,w,navH);
            e=CGRectMake(x,y+navH+g,w,h-navH-inspH-2*g);
            i=CGRectMake(x,y+h-inspH,w,inspH);
        } break;
        case 1: { // 顶栏工作台：顶部导航 + 下方检查/编辑
            n=CGRectMake(x,y,w,navH);
            i=CGRectMake(x,y+navH+g,w,inspH);
            e=CGRectMake(x,y+navH+inspH+2*g,w,h-navH-inspH-2*g);
        } break;
        case 2: { // 底部停靠：编辑/检查/底部导航
            e=CGRectMake(x,y,w,h-navH-inspH-2*g);
            i=CGRectMake(x,y+h-navH-inspH-g,w,inspH);
            n=CGRectMake(x,y+h-navH,w,navH);
        } break;
        case 3: { // 右侧工具栏
            CGFloat rw=rail;
            e=CGRectMake(x,y,w-rw-g,h-inspH-g);
            i=CGRectMake(x,y+h-inspH,w-rw-g,inspH);
            n=CGRectMake(x+w-rw,y,rw,h);
        } break;
        case 4: { // 镜像三栏：检查在上、编辑中、导航下
            i=CGRectMake(x,y,w,inspH);
            e=CGRectMake(x,y+inspH+g,w,h-inspH-navH-2*g);
            n=CGRectMake(x,y+h-navH,w,navH);
        } break;
        case 5: { // 左栏双层
            CGFloat lw=rail;
            n=CGRectMake(x,y,lw,(h-g)*0.47);
            i=CGRectMake(x,y+(h-g)*0.47+g,lw,h-(h-g)*0.47-g);
            e=CGRectMake(x+lw+g,y,w-lw-g,h);
        } break;
        case 6: { // 卡片矩阵
            CGFloat top=ZNClamp(h*0.28,92,126);
            CGFloat left=ZNClamp(w*0.40,126,158);
            n=CGRectMake(x,y,left-g*0.5,top);
            i=CGRectMake(x+left+g*0.5,y,w-left-g*0.5,top);
            e=CGRectMake(x,y+top+g,w,h-top-g);
        } break;
        case 7: { // 编辑器优先
            n=CGRectMake(x,y,w,navH-6);
            e=CGRectMake(x,y+navH-6+g,w,h-(navH-6)-inspH*0.72-2*g);
            i=CGRectMake(x,y+h-inspH*0.72,w,inspH*0.72);
        } break;
        case 8: { // 检查器优先
            i=CGRectMake(x,y,w,ZNClamp(h*0.34,110,145));
            CGFloat topH=i.size.height;
            n=CGRectMake(x,y+topH+g,w,navH-4);
            e=CGRectMake(x,y+topH+navH-4+2*g,w,h-topH-(navH-4)-2*g);
        } break;
        case 9: { // 中央核心
            CGFloat side=ZNClamp(w*0.23,76,92);
            n=CGRectMake(x,y,side,h);
            i=CGRectMake(x+w-side,y,side,h);
            e=CGRectMake(x+side+g,y,w-2*side-2*g,h);
        } break;
        case 10: { // 宽屏控制台：顶部双卡 + 主编辑区
            CGFloat th=ZNClamp(h*0.20,70,90);
            CGFloat split=(w-g)*0.46;
            n=CGRectMake(x,y,split,th);
            i=CGRectMake(x+split+g,y,w-split-g,th);
            e=CGRectMake(x,y+th+g,w,h-th-g);
        } break;
        case 11: { // 终端主视图：检查器左大卡
            CGFloat iw=inspRail;
            i=CGRectMake(x,y,iw,h);
            n=CGRectMake(x+iw+g,y,w-iw-g,navH);
            e=CGRectMake(x+iw+g,y+navH+g,w-iw-g,h-navH-g);
        } break;
        case 12: { // 双栏均分：左编辑，右上导航右下检查
            CGFloat left=ZNClamp(w*0.62,205,w-110);
            e=CGRectMake(x,y,left-g*0.5,h);
            n=CGRectMake(x+left+g*0.5,y,w-left-g*0.5,(h-g)*0.40);
            i=CGRectMake(x+left+g*0.5,y+(h-g)*0.40+g,w-left-g*0.5,h-(h-g)*0.40-g);
        } break;
        case 13: { // 上下堆叠：编辑顶部，导航中，检查底
            CGFloat midH=navH;
            CGFloat bottomH=inspH;
            e=CGRectMake(x,y,w,h-midH-bottomH-2*g);
            n=CGRectMake(x,y+h-midH-bottomH-g,w,midH);
            i=CGRectMake(x,y+h-bottomH,w,bottomH);
        } break;
        case 14: { // 左右堆叠：左导航，右编辑+检查
            CGFloat lw=rail;
            n=CGRectMake(x,y,lw,h);
            e=CGRectMake(x+lw+g,y,w-lw-g,h-inspH-g);
            i=CGRectMake(x+lw+g,y+h-inspH,w-lw-g,inspH);
        } break;
        case 15: { // 浮动卡片：三张卡内缩错位
            CGFloat inset=10;
            n=CGRectMake(x+inset,y,w-2*inset,navH);
            e=CGRectMake(x+2,y+navH+g,w-inset-2,h-navH-inspH-2*g);
            i=CGRectMake(x+inset,y+h-inspH,w-inset-2,inspH);
        } break;
        case 16: { // HUD 十字：顶导航、左检查、右编辑
            CGFloat th=navH;
            CGFloat iw=inspRail;
            n=CGRectMake(x+ZNClamp(w*0.10,20,38),y,w-ZNClamp(w*0.20,40,76),th);
            i=CGRectMake(x,y+th+g,iw,h-th-g);
            e=CGRectMake(x+iw+g,y+th+g,w-iw-g,h-th-g);
        } break;
        case 17: { // 工控台：左上导航，左下检查，右编辑
            CGFloat lw=ZNClamp(w*0.33,108,132);
            CGFloat top=(h-g)*0.36;
            n=CGRectMake(x,y,lw,top);
            i=CGRectMake(x,y+top+g,lw,h-top-g);
            e=CGRectMake(x+lw+g,y,w-lw-g,h);
        } break;
        case 18: { // 极简面板：窄顶栏 + 大编辑 + 窄底状态
            CGFloat top=44.0;
            CGFloat bottom=ZNClamp(h*0.20,72,92);
            n=CGRectMake(x,y,w,top);
            e=CGRectMake(x,y+top+g,w,h-top-bottom-2*g);
            i=CGRectMake(x,y+h-bottom,w,bottom);
        } break;
        default: { // 赛博仪表盘：左上导航、右上检查、下编辑
            CGFloat top=ZNClamp(h*0.25,86,110);
            CGFloat split=(w-g)*0.43;
            n=CGRectMake(x,y,split,top);
            i=CGRectMake(x+split+g,y,w-split-g,top);
            e=CGRectMake(x+ZNClamp(w*0.04,8,16),y+top+g,w-2*ZNClamp(w*0.04,8,16),h-top-g);
        } break;
    }

    ZNSetFrames(nav, editor, inspector, n, e, i);
    ZNRelayoutCardContents(controller);
}

static void ZNPatchedViewDidLayoutSubviews(id self, SEL _cmd) {
    if (ZNOriginalViewDidLayoutSubviews) ZNOriginalViewDidLayoutSubviews(self, _cmd);

    UIVisualEffectView *blur = [self valueForKey:@"blur"];
    if (![blur isKindOfClass:UIVisualEffectView.class]) return;
    CGRect c = blur.contentView.bounds;
    CGRect area = CGRectMake(12, 52, MAX(100.0, c.size.width - 24.0), MAX(80.0, c.size.height - 80.0));
    if (area.size.width >= 620.0) return;

    NSInteger selected = [[self valueForKey:@"selectedLayoutIndex"] integerValue];
    ZNApplyCompactLayout(self, area, selected);
}

void ZNInstallCompactLayoutFix(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = NSClassFromString(@"ZNMenuViewController");
        Method method = class_getInstanceMethod(cls, @selector(viewDidLayoutSubviews));
        if (!method) return;
        ZNOriginalViewDidLayoutSubviews = (void(*)(id,SEL))method_getImplementation(method);
        method_setImplementation(method, (IMP)ZNPatchedViewDidLayoutSubviews);
    });
}
