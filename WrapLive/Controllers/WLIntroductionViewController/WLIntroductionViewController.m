//
//  WLIntroductionViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIntroductionViewController.h"
#import "NSArray+Additions.h"
#import "WLIntroductionStepViewController.h"

@interface WLIntroductionViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, WLIntroductionStepViewControllerDelegate>

@property (weak, nonatomic) UIPageViewController* pageViewController;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (strong, nonatomic) NSArray* stepViewControllers;

@end

@implementation WLIntroductionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.stepViewControllers = @[[self.storyboard instantiateViewControllerWithIdentifier:@"introduction_step_1"],[self.storyboard instantiateViewControllerWithIdentifier:@"introduction_step_2"]];
    [self.stepViewControllers makeObjectsPerformSelector:@selector(setDelegate:) withObject:self];
    self.pageControl.numberOfPages = self.stepViewControllers.count;
    self.pageControl.currentPage = 0;
    self.pageViewController = [self.childViewControllers lastObject];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    
    [self.pageViewController setViewControllers:@[[self.stepViewControllers firstObject]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

// MARK: - <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    return [self.stepViewControllers tryObjectAtIndex:[self.stepViewControllers indexOfObject:viewController] - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    return [self.stepViewControllers tryObjectAtIndex:[self.stepViewControllers indexOfObject:viewController] + 1];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    self.pageControl.currentPage = [self.stepViewControllers indexOfObject:[pendingViewControllers lastObject]];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    self.pageControl.currentPage = [self.stepViewControllers indexOfObject:[pageViewController.viewControllers lastObject]];
}

// MARK: - WLIntroductionStepViewControllerDelegate

- (void)introductionStepViewControllerDidContinue:(WLIntroductionStepViewController *)controller {
    NSUInteger index = [self.stepViewControllers indexOfObject:[self.pageViewController.viewControllers lastObject]] + 1;
    WLIntroductionStepViewController *nextController = [self.stepViewControllers tryObjectAtIndex:index];
    if (nextController) {
        [self.pageViewController setViewControllers:@[nextController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
        self.pageControl.currentPage = index;
    }
}

- (void)introductionStepViewControllerDidFinish:(WLIntroductionStepViewController *)controller {
    [self.delegate introductionViewControllerDidFinish:self];
}

@end
