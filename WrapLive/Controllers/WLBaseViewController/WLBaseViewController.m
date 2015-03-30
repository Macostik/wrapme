//
//  WLBaseViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "UIView+AnimationHelper.h"
#import "UIView+Shorthand.h"
#import "WLNavigation.h"
#import "UIViewController+Additions.h"
#import "NSObject+NibAdditions.h"

@interface WLBaseViewController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (strong, nonatomic) NSMapTable* keyboardAdjustmentDefaultConstants;

@property (weak, nonatomic) UISwipeGestureRecognizer* backSwipeGestureRecognizer;

@property (weak, nonatomic) UIView *contentView;


@end

@implementation WLBaseViewController

+ (BOOL)isEmbeddedDefaultValue {
    return NO;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    NSString *nibName = nibNameOrNil ? : NSStringFromClass([self class]);
    if (self = [super initWithNibName:nibName bundle:nibBundleOrNil]) [self awakeAfterInit];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) [self awakeAfterInit];
    return self;
}

- (void)awakeAfterInit {
    self.isEmbedded = [[self class] isEmbeddedDefaultValue];
}

- (void)setIsEmbedded:(BOOL)isEmbedded {
    _isEmbedded = isEmbedded;
    self.modalPresentationStyle = isEmbedded ? UIModalPresentationCustom : UIModalPresentationFullScreen;
    self.transitioningDelegate = isEmbedded ? self : nil;
}

- (void)loadView {
    [super loadView];
    if (self.isEmbedded) {
        UIView *view = [[UIView alloc] initWithFrame:[UIWindow mainWindow].bounds];
        [view setFullFlexible];
        view.backgroundColor = [UIColor colorWithWhite:.0 alpha:0.5];
        UIView *contentView = self.view;
        contentView.translatesAutoresizingMaskIntoConstraints = NO;
        [view addSubview:contentView];
        
        [self addEmbeddingConstraintsToContentView:contentView inView:view];
        
        self.contentView = contentView;
        
        [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(embeddingViewTapped:)]];
        
        self.view = view;
    }
}

- (void)addEmbeddingConstraintsToContentView:(UIView *)contentView inView:(UIView *)view {
    [view addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    NSLayoutConstraint *verticalCenteringConstraint = [NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
    [view addConstraint:verticalCenteringConstraint];
    self.keyboardAdjustmentTopConstraints = [(self.keyboardAdjustmentTopConstraints?:@[]) arrayByAddingObject:verticalCenteringConstraint];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:contentView.bounds.size.width]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:contentView.bounds.size.height]];
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    return self;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self;
}

#pragma mark - UIViewControllerAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.5f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    __weak typeof(self)weakSelf = self;
    if (self.isBeingPresented) {
        fromViewController.view.userInteractionEnabled = NO;
        toViewController.view.frame = fromViewController.view.frame;
        [transitionContext.containerView addSubview:toViewController.view];
        self.contentView.transform = CGAffineTransformMakeTranslation(0, fromViewController.view.bounds.size.height);
        self.view.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.contentView.transform = CGAffineTransformIdentity;
            weakSelf.view.backgroundColor = [UIColor colorWithWhite:.0 alpha:0.5];
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
            fromViewController.view.userInteractionEnabled = YES;
        }];
    } else {
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.contentView.transform = CGAffineTransformMakeTranslation(0, fromViewController.view.bounds.size.height);
            weakSelf.view.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            weakSelf.contentView.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:YES];
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = NSStringFromClass([self class]);
    self.keyboardAdjustmentAnimated = YES;
    if (!self.isEmbedded) {
        self.view.frame = [UIWindow mainWindow].bounds;
        [self.view layoutIfNeeded];
    }
    [[WLKeyboard keyboard] addReceiver:self];
}

- (NSMapTable *)keyboardAdjustmentDefaultConstants {
    NSMapTable *constants = _keyboardAdjustmentDefaultConstants;
    if (!constants) {
        constants = [NSMapTable strongToStrongObjectsMapTable];
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        _keyboardAdjustmentDefaultConstants = constants;
    }
    return constants;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppeared = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.viewAppeared = NO;
}

- (void)setBackSwipeGestureEnabled:(BOOL)backSwipeGestureEnabled {
    if (backSwipeGestureEnabled) {
        UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(backSwipeGesture)];
        recognizer.direction = UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:recognizer];
        self.backSwipeGestureRecognizer = recognizer;
    } else if (self.backSwipeGestureRecognizer) {
        [self.view removeGestureRecognizer:self.backSwipeGestureRecognizer];
        self.backSwipeGestureRecognizer = nil;
    }
}

- (BOOL)backSwipeGestureEnabled {
    return (self.backSwipeGestureRecognizer != nil);
}

- (void)backSwipeGesture {
    if (self.isTopViewController) {
        self.backSwipeGestureEnabled = NO;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - WLKeyboardBroadcastReceiver

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight;
}

- (NSArray *)keyboardAdjustmentLayoutViews {
    if (!_keyboardAdjustmentLayoutViews.nonempty) {
        _keyboardAdjustmentLayoutViews = @[self.view];
    }
    return _keyboardAdjustmentLayoutViews;
}

- (BOOL)updateKeyboardAdjustmentConstraints:(CGFloat)adjustment {
    BOOL changed = NO;
    NSMapTable *constants = self.keyboardAdjustmentDefaultConstants;
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        constant -= adjustment;
        if (constraint.constant != constant) {
            constraint.constant = constant;
            changed = YES;
        }
    }
    for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
        CGFloat constant = [[constants objectForKey:constraint] floatValue];
        constant += adjustment;
        if (constraint.constant != constant) {
            constraint.constant = constant;
            changed = YES;
        }
    }
    return changed;
}

- (void)keyboardWillShow:(WLKeyboard *)keyboard {
    if (!self.isViewLoaded || (!self.keyboardAdjustmentTopConstraints.nonempty && !self.keyboardAdjustmentBottomConstraints.nonempty)) return;
    CGFloat adjustment = [self keyboardAdjustmentValueWithKeyboardHeight:keyboard.height];
    if ([self updateKeyboardAdjustmentConstraints:adjustment]) {
        if (self.keyboardAdjustmentAnimated && self.viewAppeared) {
            __weak typeof(self)weakSelf = self;
            [keyboard performAnimation:^{
                for (UIView *layoutView in weakSelf.keyboardAdjustmentLayoutViews) {
                    [layoutView layoutIfNeeded];
                }
            }];
        } else {
            for (UIView *layoutView in self.keyboardAdjustmentLayoutViews) {
                [layoutView layoutIfNeeded];
            }
        }
    }
}

- (void)keyboardDidShow:(WLKeyboard *)keyboard {
    
}

- (void)keyboardWillHide:(WLKeyboard *)keyboard {
    if (!self.isViewLoaded || (!self.keyboardAdjustmentTopConstraints.nonempty && !self.keyboardAdjustmentBottomConstraints.nonempty)) return;
    [self updateKeyboardAdjustmentConstraints:0];
    self.keyboardAdjustmentDefaultConstants = nil;
    if (self.keyboardAdjustmentAnimated && self.viewAppeared) {
        __weak typeof(self)weakSelf = self;
        [keyboard performAnimation:^{
            for (UIView *layoutView in weakSelf.keyboardAdjustmentLayoutViews) {
                [layoutView layoutIfNeeded];
            }
        }];
    } else {
        for (UIView *layoutView in self.keyboardAdjustmentLayoutViews) {
            [layoutView layoutIfNeeded];
        }
    }
}

- (void)keyboardDidHide:(WLKeyboard *)keyboard {
    
}

@end
