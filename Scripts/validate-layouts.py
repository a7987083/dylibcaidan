#!/usr/bin/env python3
from itertools import combinations


def clamp(v, lo, hi):
    return min(max(v, lo), hi)


def area_of_intersection(a, b):
    ax, ay, aw, ah = a; bx, by, bw, bh = b
    x1, y1 = max(ax, bx), max(ay, by)
    x2, y2 = min(ax+aw, bx+bw), min(ay+ah, by+bh)
    return max(0.0, x2-x1) * max(0.0, y2-y1)


def compact(area_w, area_h, idx):
    x=y=0.0; w=area_w; h=area_h; g=7.0
    navH=clamp(h*0.14,48,60); inspH=clamp(h*0.25,82,118)
    rail=clamp(w*0.27,88,108); inspRail=clamp(w*0.31,96,122)
    if idx == 0:
        n=(x,y,w,navH); e=(x,y+navH+g,w,h-navH-inspH-2*g); i=(x,y+h-inspH,w,inspH)
    elif idx == 1:
        n=(x,y,w,navH); i=(x,y+navH+g,w,inspH); e=(x,y+navH+inspH+2*g,w,h-navH-inspH-2*g)
    elif idx == 2:
        e=(x,y,w,h-navH-inspH-2*g); i=(x,y+h-navH-inspH-g,w,inspH); n=(x,y+h-navH,w,navH)
    elif idx == 3:
        rw=rail; e=(x,y,w-rw-g,h-inspH-g); i=(x,y+h-inspH,w-rw-g,inspH); n=(x+w-rw,y,rw,h)
    elif idx == 4:
        i=(x,y,w,inspH); e=(x,y+inspH+g,w,h-inspH-navH-2*g); n=(x,y+h-navH,w,navH)
    elif idx == 5:
        lw=rail; top=(h-g)*0.47; n=(x,y,lw,top); i=(x,y+top+g,lw,h-top-g); e=(x+lw+g,y,w-lw-g,h)
    elif idx == 6:
        top=clamp(h*0.28,92,126); left=clamp(w*0.40,126,158); n=(x,y,left-g*.5,top); i=(x+left+g*.5,y,w-left-g*.5,top); e=(x,y+top+g,w,h-top-g)
    elif idx == 7:
        nh=navH-6; ih=inspH*.72; n=(x,y,w,nh); e=(x,y+nh+g,w,h-nh-ih-2*g); i=(x,y+h-ih,w,ih)
    elif idx == 8:
        topH=clamp(h*0.34,110,145); n=(x,y+topH+g,w,navH-4); i=(x,y,w,topH); e=(x,y+topH+navH-4+2*g,w,h-topH-(navH-4)-2*g)
    elif idx == 9:
        side=clamp(w*0.23,76,92); n=(x,y,side,h); i=(x+w-side,y,side,h); e=(x+side+g,y,w-2*side-2*g,h)
    elif idx == 10:
        th=clamp(h*0.20,70,90); split=(w-g)*0.46; n=(x,y,split,th); i=(x+split+g,y,w-split-g,th); e=(x,y+th+g,w,h-th-g)
    elif idx == 11:
        iw=inspRail; i=(x,y,iw,h); n=(x+iw+g,y,w-iw-g,navH); e=(x+iw+g,y+navH+g,w-iw-g,h-navH-g)
    elif idx == 12:
        left=clamp(w*0.62,205,w-110); e=(x,y,left-g*.5,h); n=(x+left+g*.5,y,w-left-g*.5,(h-g)*.40); i=(x+left+g*.5,y+(h-g)*.40+g,w-left-g*.5,h-(h-g)*.40-g)
    elif idx == 13:
        e=(x,y,w,h-navH-inspH-2*g); n=(x,y+h-navH-inspH-g,w,navH); i=(x,y+h-inspH,w,inspH)
    elif idx == 14:
        lw=rail; n=(x,y,lw,h); e=(x+lw+g,y,w-lw-g,h-inspH-g); i=(x+lw+g,y+h-inspH,w-lw-g,inspH)
    elif idx == 15:
        inset=10; n=(x+inset,y,w-2*inset,navH); e=(x+2,y+navH+g,w-inset-2,h-navH-inspH-2*g); i=(x+inset,y+h-inspH,w-inset-2,inspH)
    elif idx == 16:
        th=navH; iw=inspRail; left_inset=clamp(w*.10,20,38); n=(x+left_inset,y,w-2*left_inset,th); i=(x,y+th+g,iw,h-th-g); e=(x+iw+g,y+th+g,w-iw-g,h-th-g)
    elif idx == 17:
        lw=clamp(w*.33,108,132); top=(h-g)*.36; n=(x,y,lw,top); i=(x,y+top+g,lw,h-top-g); e=(x+lw+g,y,w-lw-g,h)
    elif idx == 18:
        top=44.0; bottom=clamp(h*.20,72,92); n=(x,y,w,top); e=(x,y+top+g,w,h-top-bottom-2*g); i=(x,y+h-bottom,w,bottom)
    else:
        top=clamp(h*.25,86,110); split=(w-g)*.43; inset=clamp(w*.04,8,16); n=(x,y,split,top); i=(x+split+g,y,w-split-g,top); e=(x+inset,y+top+g,w-2*inset,h-top-g)
    return n,e,i


def inside(rect, w, h):
    x,y,rw,rh=rect
    return rw > 0 and rh > 0 and x >= -0.5 and y >= -0.5 and x+rw <= w+0.5 and y+rh <= h+0.5


def validate():
    sizes=[(296,420),(340,420),(354,420),(394,420),(354,360),(394,460)]
    for w,h in sizes:
        signatures=set()
        for idx in range(20):
            rects=compact(w,h,idx)
            assert all(inside(r,w,h) for r in rects), (w,h,idx,rects)
            for a,b in combinations(rects,2):
                assert area_of_intersection(a,b) < 1.0, (w,h,idx,a,b)
            # v0.3.2 has a dedicated two-row narrow editor mode down to 125pt.
            ex,ey,ew,eh=rects[1]
            assert ew >= 125 and eh >= 145, (w,h,idx,'editor too small',rects[1])
            signatures.add(tuple(round(v,1) for r in rects for v in r))
        assert len(signatures) == 20, (w,h,'layouts not distinct',len(signatures))

    # Compact header: title must not collide with status or layout selector.
    for width in (320, 350, 375, 390, 430):
        statusW=74.0; statusX=max(240.0,width-12.0-statusW)
        subtitleW=min(104.0,max(76.0,width*.27)); layoutX=58+subtitleW+5; layoutW=max(88.0,statusX-layoutX-7)
        if layoutW < 96:
            layoutX=58+72+4; layoutW=max(88.0,statusX-layoutX-7)
        title=(58,5,max(120,statusX-64),21); status=(statusX,9,statusW,25); layout=(layoutX,25,layoutW,26)
        assert area_of_intersection(title,status) < 1.0, (width,'title/status overlap')
        assert layout[0]+layout[2] <= statusX+0.5, (width,'layout/status overlap')

    # Picker is intentionally scrollable: every item must lie inside scroll content.
    for picker_w,picker_h in ((302,300),(350,360),(390,380),(700,380)):
        cols=4 if picker_w >= 620 else 2; rows=(20+cols-1)//cols
        scroll_w=picker_w-20; scroll_h=picker_h-53; gap=7; pad=3; itemH=38
        bw=max(92,(scroll_w-2*pad-(cols-1)*gap)/cols)
        content_h=2*pad+rows*itemH+max(0,rows-1)*gap
        assert content_h >= scroll_h or rows <= 5
        for idx in range(20):
            r=idx//cols; c=idx%cols
            x=pad+c*(bw+gap); y=pad+r*(itemH+gap)
            assert x+bw <= scroll_w+0.5 and y+itemH <= content_h+0.5

    print('v0.3.2 geometry regression: PASS')


if __name__ == '__main__':
    validate()
