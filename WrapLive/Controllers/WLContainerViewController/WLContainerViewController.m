//
//  WLContainerViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/9/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContainerViewController.h"
#import "WLNavigation.h"
#import "NSObject+NibAdditions.h"

@interface WLContainerViewController () <UIViewControllerTransitioningDelegate, UIViewControllerAnimatedTransitioning>

@property (weak, nonatomic) UIView *contentView;

@end

@implementation WLContainerViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    return self;
}

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIWindow mainWindow].bounds];
    view.backgroundColor = [UIColor colorWithWhite:.0 alpha:0.5];
    NSString *nibName = self.nibName ? : NSStringFromClass([self class]);
    if (!nibName.nonempty) return;
    UIView *contentView = [UIView loadFromNibNamed:nibName ownedBy:self];
    if (!contentView) return;
    [view addSubview:contentView];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:contentView.bounds.size.width]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:contentView.bounds.size.height]];
    self.contentView = contentView;
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
        }];
    } else {
        toViewController.view.userInteractionEnabled = YES;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.3 options:UIViewAnimationOptionCurveEaseIn animations:^{
            weakSelf.contentView.transform = CGAffineTransformMakeTranslation(0, fromViewController.view.bounds.size.height);
            weakSelf.view.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            weakSelf.contentView.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:YES];
        }];
    }
}

@end
