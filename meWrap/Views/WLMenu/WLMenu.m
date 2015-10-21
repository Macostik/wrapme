//
//  WLMenu.m
//  meWrap
//
//  Created by Ravenpod on 6/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMenu.h"
#import <AudioToolbox/AudioServices.h>
#import "UIFont+CustomFonts.h"
#import "WLButton.h"
#import "WLDeviceManager.h"

@class WLMenuItem;

@interface WLMenuItem : WLButton

@property (strong, nonatomic) WLObjectBlock block;

@end

@implementation WLMenuItem

- (instancetype)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, 38, 38);
        self.clipsToBounds = NO;
        [self setBackgroundImage:[UIImage imageNamed:@"bg_menu_btn"] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont fontWithName:@"icons" size:21];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self setTitleColor:WLColors.grayLight forState:UIControlStateHighlighted];
        self.layer.cornerRadius = self.bounds.size.width/2;
    }
    return self;
}

@end

@interface WLMenu ()

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
    BOOL contains = [self removeView:view];
    [self.views setObject:view forKey:configuration];
    if (!contains) {
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(present:)];
        [view addGestureRecognizer:recognizer];
    }
}

- (BOOL)removeView:(UIView *)view {
    NSMapTable *views = self.views;
    for (id key in views) {
        UIView *_view = [views objectForKey:key];
        if (_view == view) {
            [views removeObjectForKey:key];
            return YES;
        }
    }
    return NO;
}

- (void)hide {
    if (self.visible) {
        [self setHidden:YES animated:YES];
        [[WLDeviceManager manager] removeReceiver:self];
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
    
    [[WLDeviceManager manager] addReceiver:self];
    self.currentView = view;
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    WLMenuConfiguration configuration = [self configurationForView:view];
    
    self.entry = nil;
    self.vibrate = YES;
    
    if (configuration) {
        configuration(self);
        
        if (!self.subviews.nonempty) return;
        
        if (self.vibrate) AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        [self setHidden:NO animated:animated];
    }
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated {
    __weak typeof(self)weakSelf = self;

    void (^showBlock)(void) = ^{
        CGFloat count = [weakSelf.subviews count];
        CGFloat range = (M_PI_4)*count;
        CGFloat delta = -M_PI_2;
        if (weakSelf.centerPoint.x >= 2*self.width/3) {
            delta -= range;
        } else if (weakSelf.centerPoint.x >= self.width/3) {
            delta -= range/2;
        }
        CGFloat radius = 60;
        
        [weakSelf.subviews enumerateObjectsUsingBlock:^(WLMenuItem* item, NSUInteger idx, BOOL *stop) {
            CGFloat angle = 0;
            if (count > 1) {
                angle = range*((float)idx/(count - 1)) + delta;
            } else {
                angle = delta;
            }
            
            CGPoint center = item.center;
//          center.x = Smoothstep(subview.width/2, superview.width - subview.width/2, center.x + radius*cosf(angle));;
//          center.y = Smoothstep(subview.height/2, superview.height - subview.height/2, center.y + radius*sinf(angle));
            center.x = center.x + radius*cosf(angle);
            center.y = center.y + radius*sinf(angle);
            item.center = center;
        }];
    };
    
    void (^hideBlock)(void) = ^{
        for (WLMenuItem *item in weakSelf.subviews) {
            item.center = weakSelf.centerPoint;
        }
    };
    
    void (^hideCompletionBlock)(BOOL) = ^(BOOL finished){
        [weakSelf.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
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

- (void)addItemWithText:(NSString*)text block:(WLObjectBlock)block {
    WLMenuItem* item = [[WLMenuItem alloc] init];
    [item setTitle:text forState:UIControlStateNormal];
    [self addSubview:item];
    [item addTarget:self action:@selector(selectedItem:) forControlEvents:UIControlEventTouchUpInside];
    item.center = self.centerPoint;
    item.block = block;
}

- (void)present:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan && sender.view.userInteractionEnabled) {
        [self showInView:sender.view point:[sender locationInView:sender.view] animated:YES];
	}
}

- (void)selectedItem:(WLMenuItem*)sender {
    WLObjectBlock block = sender.block;
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

- (void)manager:(WLDeviceManager*)manager didChangeOrientation:(NSNumber*)orientation {
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
