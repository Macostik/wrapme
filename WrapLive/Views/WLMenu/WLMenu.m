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

@implementation WlMenuItemButton

+ (id)buttonWithType:(UIButtonType)buttonType {
    WlMenuItemButton *button = [super buttonWithType:buttonType];
    return button;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.backgroundColor = highlighted ? [UIColor WL_darkGrayColor] : [UIColor blackColor];
}

@end

@interface WLMenu ()

@property (strong, nonatomic) NSMutableArray* items;

@property (strong, nonatomic) NSArray* buttons;

@property (weak, nonatomic) UILongPressGestureRecognizer* longPressGestureRecognizer;

@property (nonatomic) BOOL hiding;

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

- (void)hide {
    self.hiding = YES;
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [weakSelf.buttons enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL *stop) {
            subview.alpha = 0.0f;
        }];
    } completion:^(BOOL finished) {
        [weakSelf.items removeAllObjects];
        [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
        weakSelf.hiding = NO;
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
        _point = [self.view convertPoint:point toView:superview];
        [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
        CGFloat count = [self.items count];
        NSMutableArray* buttons = [NSMutableArray array];
        for (WLMenuItem* item in self.items) {
            WlMenuItemButton* button = [WlMenuItemButton buttonWithType:UIButtonTypeCustom];
            button.item = item;
            [superview addSubview:button];
            [button addTarget:self action:@selector(selectedItem:) forControlEvents:UIControlEventTouchUpInside];
            button.frame = CGRectMake(0, 0, 88, 40);
            button.center = _point;
            button.backgroundColor = [UIColor blackColor];
            button.clipsToBounds = NO;
            [button setTitle:item.title forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button.titleLabel setFont:[UIFont regularSmallFont]];
            button.layer.cornerRadius = 10;
            CGFloat angle = 2*M_PI*((float)[buttons count]/count) - M_PI_4;
            CGPoint center = button.center;
            center.x += 44*cosf(angle);
            center.y += 44*sinf(angle);
            button.center = center;
            button.alpha = 0.0f;
            [buttons addObject:button];
            
            UIImageView* arrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_menu_arrow"]];
            arrow.x = button.width/2.0f - arrow.width/2.0f;
            arrow.y = button.height;
            [button addSubview:arrow];
        }
        self.buttons = [buttons copy];
        __weak typeof(self)weakSelf = self;
        [UIView animateWithDuration:0.2 delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [weakSelf.buttons enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL *stop) {
                subview.alpha = 1.0f;
            }];
        } completion:^(BOOL finished) {
        }];
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
        sender.view.userInteractionEnabled = NO;
        [self show:[sender locationInView:sender.view]];
        sender.view.userInteractionEnabled = YES;
	}
}

- (void)selectedItem:(WlMenuItemButton*)sender {
    WLBlock block = sender.item.block;
    if (block) {
        block();
    }
    [self hide];
}

@end

@implementation WLWindow

- (void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];
    if (event.type != UIEventTypeTouches) {
        return;
    }
    NSSet* touches = [event allTouches];
    if ([touches count] != 1) {
        return;
    }
    UITouch* touch = [touches anyObject];
    if (touch.phase != UITouchPhaseBegan) {
        return;
    }
    for (WLMenu* menu in [WLMenu menus]) {
        if (menu.hiding) {
            continue;
        }
        BOOL hide = YES;
        
        for (UIButton* button in menu.buttons) {
            if (CGRectContainsPoint(button.frame, [touch locationInView:self])) {
                hide = NO;
                break;
            }
        }
        if (hide) {
            [menu hide];
        }
    }
}

@end
