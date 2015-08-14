//
//  WLMenu.m
//  moji
//
//  Created by Ravenpod on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMenu.h"
#import <AudioToolbox/AudioServices.h>
#import "UIFont+CustomFonts.h"
#import "UIView+AnimationHelper.h"
#import "WLButton.h"
#import "WLDeviceOrientationBroadcaster.h"

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
    [button setBackgroundImage:[UIImage imageNamed:@"bg_menu_btn"] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:@"icons" size:21];
    [button setTitle:item.text forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:WLColors.grayLight forState:UIControlStateHighlighted];
    button.layer.cornerRadius = button.bounds.size.width/2;
    return button;
}

@end

@interface WLMenu ()

@property (strong, nonatomic) NSMutableArray* items;

@property (strong, nonatomic) NSArray* buttons;

@property (weak, nonatomic) UILongPressGestureRecognizer* longPressGestureRecognizer;

@property (nonatomic) CGPoint centerPoint;

@property (strong, nonatomic) NSMapTable* views;

@property (weak, nonatomic) UIView* currentView;

@end

@implementation WLMenu

+ (instancetype)sharedMenu {
    static id instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.views = [NSMapTable strongToWeakObjectsMapTable];
        self.items = [NSMutableArray array];
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.0f;
        [self setFullFlexible];
    }
    return self;
}

- (BOOL)visible {
    return self.superview != nil;
}

- (void)addView:(UIView *)view configuration:(WLMenuConfiguration)configuration {
    NSMapTable *views = self.views;
    BOOL contains = NO;
    for (id key in views) {
        UIView *_view = [views objectForKey:key];
        if (_view == view) {
            [views removeObjectForKey:key];
            contains = YES;
            break;
        }
    }
    [views setObject:view forKey:configuration];
    if (!contains) {
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(present:)];
        [view addGestureRecognizer:recognizer];
    }
}

- (void)hide {
    if (self.visible) {
        [self setHidden:YES animated:YES];
        [[WLDeviceOrientationBroadcaster broadcaster] removeReceiver:self];
    }
}

- (WLMenuConfiguration)configurationForView:(UIView*)view {
    NSMapTable *views = self.views;
    for (id configuration in views) {
        UIView *_view = [views objectForKey:configuration];
        if (_view == view) {
            return configuration;
        }
    }
    return nil;
}

- (void)showInView:(UIView*)view point:(CGPoint)point animated:(BOOL)animated {
    UIView* superview = view.window;
    if (!superview) {
        return;
    }
    
    self.centerPoint = [view convertPoint:point toView:superview];
    CGRect _rect = [superview convertRect:view.bounds fromView:view];
    if (!CGRectContainsPoint(_rect, self.centerPoint)) {
        return;
    }
    
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
    self.currentView = view;
    [self.items removeAllObjects];
    [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    WLMenuConfiguration configuration = [self configurationForView:view];
    
    self.entry = nil;
    if (configuration) {
        BOOL vibrate = YES;
        self.entry = configuration(self, &vibrate);
        
        if (!self.items.nonempty) return;
        
        if (vibrate) AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        __weak typeof(self)weakSelf = self;
        self.buttons = [self.items map:^id(WLMenuItem* item) {
            WlMenuItemButton* button = [WlMenuItemButton buttonWithItem:item];
            [self addSubview:button];
            [button addTarget:self action:@selector(selectedItem:) forControlEvents:UIControlEventTouchUpInside];
            button.center = weakSelf.centerPoint;
            return button;
        }];
        
        [self setHidden:NO animated:animated];
    }
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;

    void (^showBlock)(void) = ^{
        CGFloat count = [weakSelf.items count];
        CGFloat range = (M_PI_4)*count;
        CGFloat delta = -M_PI_2;
        if (weakSelf.centerPoint.x >= 2*self.width/3) {
            delta -= range;
        } else if (weakSelf.centerPoint.x >= self.width/3) {
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
//          center.x = Smoothstep(subview.width/2, superview.width - subview.width/2, center.x + radius*cosf(angle));;
//          center.y = Smoothstep(subview.height/2, superview.height - subview.height/2, center.y + radius*sinf(angle));
            center.x = center.x + radius*cosf(angle);
            center.y = center.y + radius*sinf(angle);
            subview.center = center;
        }];
    };
    
    void (^hideBlock)(void) = ^{
        [weakSelf.buttons enumerateObjectsUsingBlock:^(UIView* subview, NSUInteger idx, BOOL *stop) {
            subview.center = weakSelf.centerPoint;
        }];
    };
    
    void (^hideCompletionBlock)(BOOL) = ^(BOOL finished){
        [weakSelf.items removeAllObjects];
        [weakSelf.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [weakSelf removeFromSuperview];
    };
    
    if (!hidden) {
        UIView* superview = self.currentView.window;
        self.frame = superview.bounds;
        [superview addSubview:self];
        [self setNeedsDisplay];
        self.alpha = 0.0f;
    }
    
    if (animated) {
        [UIView animateWithDuration:0.12f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.alpha = hidden ? 0.0f : 1.0f;
        } completion:nil];
        if (hidden) {
            [UIView animateWithDuration:0.12f animations:hideBlock completion:hideCompletionBlock];
        } else {
            [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseIn animations:showBlock completion:nil];
        }
    } else {
        weakSelf.alpha = hidden ? 0.0f : 1.0f;
        if (hidden) {
            hideCompletionBlock(YES);
        } else {
            showBlock();
        }
    }
    
    if (hidden) {
        self.entry = nil;
    }
}

- (WLMenuItem *)addItem:(WLObjectBlock)block {
    if (!self.items) self.items = [NSMutableArray array];
    WLMenuItem* item = [[WLMenuItem alloc] init];
    item.block = block;
    [self.items addObject:item];
    return item;
}

- (void)addItemWithText:(NSString*)text block:(WLObjectBlock)block; {
    [self addItem:block].text = text;
}

- (void)present:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan && sender.view.userInteractionEnabled) {
        [self showInView:sender.view point:[sender locationInView:sender.view] animated:YES];
	}
}

- (void)selectedItem:(WlMenuItemButton*)sender {
    WLObjectBlock block = sender.item.block;
    if (self.entry) {
        if (block) block(self.entry);
    }
    [self hide];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    UIColor *color = [UIColor colorWithWhite:0 alpha:.6];
    
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillRect (ctx, rect);
    
    CGRect frame = [self convertRect:self.currentView.bounds fromView:self.currentView];
    
    CGContextSetShadowWithColor (ctx, CGSizeZero, 15.0, color.CGColor);
    CGContextClearRect(ctx, frame);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self hide];
}

- (void)broadcaster:(WLDeviceOrientationBroadcaster*)broadcaster didChangeOrientation:(NSNumber*)orientation {
    [self hide];
}

@end

@implementation WLMenu (DefinedItems)

- (void)addDeleteItem:(WLObjectBlock)block {
    [self addItemWithText:@"n" block:block];
}

- (void)addLeaveItem:(WLObjectBlock)block {
    [self addItemWithText:@"O" block:block];
}

- (void)addReportItem:(WLObjectBlock)block {
    [self addItemWithText:@"s" block:block];
}

- (void)addDownloadItem:(WLObjectBlock)block {
    [self addItemWithText:@"o" block:block];
}

- (void)addCopyItem:(WLObjectBlock)block {
    [self addItemWithText:@"Q" block:block];
}

- (void)addEditPhotoItem:(WLObjectBlock)block {
    [self addItemWithText:@"R" block:block];
}

- (void)addDrawPhotoItem:(WLObjectBlock)block {
    [self addItemWithText:@"8" block:block];
}

@end
