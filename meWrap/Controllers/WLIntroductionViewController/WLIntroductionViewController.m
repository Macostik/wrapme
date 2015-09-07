//
//  WLIntroductionViewController.m
//  meWrap
//
//  Created by Ravenpod on 3/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLIntroductionViewController.h"
#import "WLIntroductionBaseViewController.h"

@interface WLIntroductionViewController () <WLIntroductionBaseViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (strong, nonatomic) NSArray* stepViewControllers;

@end

@implementation WLIntroductionViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.stepViewControllers = @[[self.storyboard instantiateViewControllerWithIdentifier:@"introduction_step_1"],[self.storyboard instantiateViewControllerWithIdentifier:@"introduction_step_2"]];
    for (WLIntroductionBaseViewController *controller in self.stepViewControllers) {
        controller.delegate = self;
        controller.view.backgroundColor = [UIColor clearColor];
    }
    self.pageControl.numberOfPages = self.stepViewControllers.count;
    self.pageControl.currentPage = 0;
    [self setViewController:[self.stepViewControllers firstObject] direction:0 animated:NO];
}

// MARK: - <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

- (UIViewController *)viewControllerBeforeViewController:(UIViewController *)viewController {
    return [self.stepViewControllers tryAt:[self.stepViewControllers indexOfObject:viewController] - 1];
}

- (UIViewController *)viewControllerAfterViewController:(UIViewController *)viewController {
    return [self.stepViewControllers tryAt:[self.stepViewControllers indexOfObject:viewController] + 1];
}

- (void)didChangeViewController:(UIViewController *)viewController {
    self.pageControl.currentPage = [self.stepViewControllers indexOfObject:viewController];
}

// MARK: - WLIntroductionBaseViewControllerInteractionDelegate

- (void)introductionBaseViewControllerDidContinueIntroduction:(WLIntroductionBaseViewController *)controller {
    UIViewController *nextController = [self viewControllerAfterViewController:self.viewController];
    if (nextController) {
        __weak typeof(self)weakSelf = self;
        self.view.userInteractionEnabled = NO;
        [self setViewController:nextController direction:WLSwipeViewControllerDirectionForward animated:YES completion:^{
            weakSelf.view.userInteractionEnabled = YES;
        }];
    }
}

- (void)introductionBaseViewControllerDidFinishIntroduction:(WLIntroductionBaseViewController *)controller {
    [self.delegate introductionViewControllerDidFinish:self];
}

@end
