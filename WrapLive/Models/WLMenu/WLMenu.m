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

@implementation WLMenuItem @end

@interface WlMenuItemButton : UIButton

@property (weak, nonatomic) WLMenuItem* item;

@end

@implementation WlMenuItemButton @end

@interface WLMenu ()

@property (strong, nonatomic) NSMutableArray* items;

@property (weak, nonatomic) UILongPressGestureRecognizer* longPressGestureRecognizer;

@end

@implementation WLMenu
{
    BOOL _vibrate:YES;
    CGPoint _point;
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
        self.view = view;
        self.backgroundColor = [UIColor clearColor];
        self.configuration = configuration;
        [[WLMenu menus] addObject:self];
        UILongPressGestureRecognizer* longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(present:)];
        [view addGestureRecognizer:longPressGestureRecognizer];
        self.longPressGestureRecognizer = longPressGestureRecognizer;
    }
    return self;
}

- (instancetype)initWithView:(UIView *)view title:(NSString *)title block:(WLBlock)block {
    return [self initWithView:view configuration:^BOOL (WLMenu *menu) {
        [menu addItem:title block:block];
        return YES;
    }];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    self.longPressGestureRecognizer.enabled = enabled;
}

- (void)hide {
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.33 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        weakSelf.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [weakSelf.items removeAllObjects];
        [weakSelf removeFromSuperview];
    }];
}

- (void)show {
    [self show:self.view.center];
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
        self.frame = superview.bounds;
        _point = [self.view convertPoint:point toView:superview];
        [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        for (WLMenuItem* item in self.items) {
            WlMenuItemButton* button = [WlMenuItemButton buttonWithType:UIButtonTypeCustom];
            button.item = item;
            [self addSubview:button];
            [button addTarget:self action:@selector(selectedItem:) forControlEvents:UIControlEventTouchUpInside];
            button.frame = CGRectMake(0, 0, 88, 44);
            button.center = _point;
            button.backgroundColor = [UIColor blackColor];
            button.clipsToBounds = YES;
            [button setTitle:item.title forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont regularSmallFont]];
            button.layer.cornerRadius = 10;
        }
        self.alpha = 0.0f;
        [superview addSubview:self];
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.33 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            weakSelf.alpha = 1.0f;
            CGFloat count = [weakSelf.subviews count];
            [weakSelf.subviews enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL *stop) {
                CGFloat angle = 2*M_PI*((float)idx/count) - M_PI_4;
                CGPoint center = subview.center;
                center.x += 44*cosf(angle);
                center.y += 44*sinf(angle);
                subview.center = center;
            }];
        } completion:^(BOOL finished) {
        }];
        [self setNeedsDisplay];
    }
}

- (void)addItem:(NSString *)title block:(WLBlock)block {
    if (!self.items) {
        self.items = [NSMutableArray array];
    }
    WLMenuItem* item = [[WLMenuItem alloc] init];
    item.title = title;
    item.block = block;
    [self.items addObject:item];
}

- (void)present:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan && sender.view.userInteractionEnabled) {
		if (self.vibrate) {
			AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
		}
        [self show:[sender locationInView:sender.view]];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self hide];
}

- (void)selectedItem:(WlMenuItemButton*)sender {
    WLBlock block = sender.item.block;
    if (block) {
        block();
    }
    [self hide];
}

@end
