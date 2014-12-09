//
//  WLMenu.m
//  WrapLive
//
//  Created by Sergey Maximenko on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMenu.h"
#import <AudioToolbox/AudioServices.h>
#import "UIFont+CustomFonts.h"
#import "UIColor+CustomColors.h"
#import "UIView+Shorthand.h"
#import "NSArray+Additions.h"
#import "UIView+AnimationHelper.h"
#import "WLButton.h"

@implementation WLMenuItem @end

@interface WlMenuItemButton : WLButton

@property (weak, nonatomic) WLMenuItem* item;

+ (WlMenuItemButton*)buttonWithItem:(WLMenuItem*)item;

@end

@implementation WlMenuItemButton

+ (id)buttonWithType:(UIButtonType)buttonType {
    WlMenuItemButton *button = [super buttonWithType:buttonType];
    return button;
}

+ (WlMenuItemButton *)buttonWithItem:(WLMenuItem *)item {
    WlMenuItemButton* button = [WlMenuItemButton buttonWithType:UIButtonTypeCustom];
    button.item = item;
    button.frame = CGRectMake(0, 0, 38, 38);
    button.clipsToBounds = NO;
    if (item.title) {
        [button setTitle:item.title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont regularMicroFont]];
    }
    [button setBackgroundImage:[UIImage imageNamed:@"bg_menu_btn"] forState:UIControlStateNormal];
    [button setImage:item.image forState:UIControlStateNormal];
    button.layer.cornerRadius = button.bounds.size.width/2;
    return button;
}

@end

@interface WLMenu ()

@property (strong, nonatomic) NSMutableArray* items;

@property (strong, nonatomic) NSArray* buttons;

@property (weak, nonatomic) UILongPressGestureRecognizer* longPressGestureRecognizer;

@property (nonatomic) BOOL visible;

@property (nonatomic) CGPoint centerPoint;

@end

@implementation WLMenu
{
    BOOL _vibrate:YES;
}

@synthesize vibrate = _vibrate;

+ (NSHashTable*)menus {
    static NSHashTable *menus = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        menus = [NSHashTable weakObjectsHashTable];
    });
    return menus;
}

+ (instancetype)menuWithView:(UIView *)view configuration:(BOOL (^)(WLMenu *))configuration {
    return [[self alloc] initWithView:view configuration:configuration];
}

+ (instancetype)menuWithView:(UIView *)view title:(NSString *)title block:(WLBlock)block {
    return [[self alloc] initWithView:view title:title block:block];
}

+ (void)hide {
    for (WLMenu* menu in [self menus]) {
        [menu hide];
    }
}

- (instancetype)initWithView:(UIView *)view configuration:(BOOL (^)(WLMenu *))configuration {
    self = [super init];
    if (self) {
        self.configuration = configuration;
        [self setup:view];
    }
    return self;
}

- (instancetype)initWithView:(UIView *)view title:(NSString *)title block:(WLBlock)block {
    return [self initWithView:view configuration:^BOOL (WLMenu *menu) {
        [menu addItemWithTitle:title block:block];
        return YES;
    }];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup:self];
}

- (void)setup:(UIView*)view {
    self.backgroundColor = [UIColor clearColor];
    [self setHidden:YES animated:NO];
    self.view = view;
    [[WLMenu menus] addObject:self];
    [view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(present:)]];
}

- (void)hide {
    self.visible = NO;
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [weakSelf.items removeAllObjects];
        [weakSelf.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [weakSelf removeFromSuperview];
    }];
}

- (void)show {
    [self show:self.center];
}

- (void)show:(CGPoint)point {
    UIView* superview = self.view.window;
    if (!superview) {
        return;
    }
    if (!self.items) {
        self.items = [NSMutableArray array];
    } else {
        [self.items removeAllObjects];
    }
    if (self.configuration && self.configuration(self)) {
        self.visible = YES;
        self.centerPoint = [self.view convertPoint:point toView:superview];
        [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        __weak typeof(self)weakSelf = self;
        self.buttons = [self.items map:^id(WLMenuItem* item) {
            WlMenuItemButton* button = [WlMenuItemButton buttonWithItem:item];
            [self addSubview:button];
            [button addTarget:self action:@selector(selectedItem:) forControlEvents:UIControlEventTouchUpInside];
            button.center = weakSelf.centerPoint;
            return button;
        }];
        self.frame = superview.bounds;
        [superview addSubview:self];
        [self setNeedsDisplay];
        [self setButtonsHidden:NO animated:YES];
        [self setHidden:NO animated:YES];
    }
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        [UIView setAnimationDuration:0.3];
        weakSelf.alpha = hidden ? 0.0f : 1.0f;
    }];
}

- (void)setButtonsHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;
    [UIView performAnimated:animated animation:^{
        [UIView setAnimationDuration:0.3];
        if (hidden) {
            [weakSelf.buttons enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL *stop) {
                subview.center = weakSelf.centerPoint;
            }];
        } else {
            CGFloat count = [weakSelf.items count];
            UIView* superview = weakSelf.view.window;
            CGFloat range = (M_PI_4)*count;
            CGFloat delta = -M_PI_2;
            if (weakSelf.centerPoint.x >= 2*superview.width/3) {
                delta -= range;
            } else if (weakSelf.centerPoint.x >= superview.width/3) {
                delta -= range/2;
            }
            CGFloat radius = 60;
            [weakSelf.buttons enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL *stop) {
                CGFloat angle = 0;
                if (count > 1) {
                    angle = range*((float)idx/(count - 1)) + delta;
                } else {
                    angle = delta;
                }
                
                CGPoint center = subview.center;
//                center.x = Smoothstep(subview.width/2, superview.width - subview.width/2, center.x + radius*cosf(angle));;
//                center.y = Smoothstep(subview.height/2, superview.height - subview.height/2, center.y + radius*sinf(angle));
                center.x = center.x + radius*cosf(angle);
                center.y = center.y + radius*sinf(angle);
                subview.center = center;
            }];
        }
    }];
}

- (WLMenuItem *)addItem:(WLBlock)block {
    if (!self.items) self.items = [NSMutableArray array];
    WLMenuItem* item = [[WLMenuItem alloc] init];
    item.block = block;
    [self.items addObject:item];
    return item;
}

- (void)addItemWithTitle:(NSString *)title block:(WLBlock)block {
    WLMenuItem* item = [self addItem:block];
    item.title = title;
}

- (void)addItemWithImage:(UIImage *)image block:(WLBlock)block {
    WLMenuItem* item = [self addItem:block];
    item.image = image;
}

- (void)present:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan && sender.view.userInteractionEnabled) {
		if (self.vibrate) {
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		}
        [self show:[sender locationInView:sender.view]];
	}
}

- (void)selectedItem:(WlMenuItemButton*)sender {
    WLBlock block = sender.item.block;
    if (block) {
        block();
    }
    [self hide];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    NSArray* colors = @[(id)[UIColor colorWithWhite:0.0f alpha:0.0f].CGColor, (id)[UIColor colorWithWhite:0.0f alpha:0.9f].CGColor];
    CGFloat locations[2] = {0,1};
    CGGradientRef gr = CGGradientCreateWithColors(cs, (__bridge CFArrayRef)colors, locations);
    CGContextDrawRadialGradient(ctx, gr, self.centerPoint, 0, self.centerPoint, 80, kCGGradientDrawsAfterEndLocation);
    CGColorSpaceRelease(cs);
    CGGradientRelease(gr);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self hide];
}

@end

@implementation WLMenu (DefinedItems)

- (void)addDeleteItem:(WLBlock)block {
    [self addItemWithImage:[UIImage imageNamed:@"btn_menu_delete"] block:block];
}

- (void)addLeaveItem:(WLBlock)block {
    [self addItemWithImage:[UIImage imageNamed:@"btn_menu_leave"] block:block];
}

- (void)addReportItem:(WLBlock)block {
    [self addItemWithImage:[UIImage imageNamed:@"btn_menu_alert"] block:block];
}

- (void)addDownloadItem:(WLBlock)block {
    [self addItemWithImage:[UIImage imageNamed:@"btn_menu_download"] block:block];
}

@end
