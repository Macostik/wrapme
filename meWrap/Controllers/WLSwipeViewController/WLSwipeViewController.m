//
//  WLSwipeViewController.m
//  meWrap
//
//  Created by Ravenpod on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeViewController.h"
#import "UIView+Extentions.h"
#import "UIScrollView+Additions.h"

@interface WLSwipeViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView* scrollView;

@property (nonatomic) BOOL swiping;

@property (weak, nonatomic) UIViewController *secondViewController;

@property (strong, nonatomic) NSMutableArray *viewControllers;

@end

@implementation WLSwipeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIScrollView *scrollView = self.scrollView;
    
    scrollView.alwaysBounceHorizontal = YES;
    
    scrollView.alwaysBounceVertical = NO;
    
    scrollView.showsHorizontalScrollIndicator = scrollView.showsVerticalScrollIndicator = NO;
    
    scrollView.pagingEnabled = YES;
    
    scrollView.delegate = self;
    
    scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    [scrollView.panGestureRecognizer addTarget:self action:@selector(panning:)];
}

- (UIViewController*)viewControllerAfterViewController:(UIViewController*)viewController {
    return nil;
}

- (UIViewController*)viewControllerBeforeViewController:(UIViewController*)viewController {
    return nil;
}

- (void)setViewController:(UIViewController*)viewController direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated {
    [self setViewController:viewController direction:direction animated:animated completion:nil];
}

- (void)setViewController:(UIViewController*)viewController direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated completion:(WLBlock)completion {
    if (animated && self.viewController) {
        __weak typeof(self)weakSelf = self;
        if (direction == WLSwipeViewControllerDirectionForward) {
            self.secondViewController = self.viewController;
            self.secondViewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
            _viewController = nil;
            self.viewController = viewController;
            self.viewController.view.frame = CGRectMake(self.scrollView.size.width, 0, self.scrollView.size.width, self.scrollView.size.height);
            self.scrollView.contentSize = CGSizeMake(self.scrollView.width * 2, self.scrollView.height);
            self.scrollView.contentOffset = CGPointZero;
            [self.scrollView setContentOffset:CGPointMake(self.scrollView.width, 0) animated:YES];
            run_after(0.5, ^{
                [weakSelf scrollViewDidEndDecelerating:weakSelf.scrollView];
                if (completion) completion();
            });
        } else {
            self.secondViewController = self.viewController;
            self.secondViewController.view.frame = CGRectMake(self.scrollView.size.width, 0, self.scrollView.size.width, self.scrollView.size.height);
            _viewController = nil;
            self.viewController = viewController;
            self.viewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
            self.scrollView.contentSize = CGSizeMake(self.scrollView.width * 2, self.scrollView.height);
            self.scrollView.contentOffset = CGPointMake(self.scrollView.width, 0);
            [self.scrollView setContentOffset:CGPointZero animated:YES];
            run_after(0.5, ^{
                [weakSelf scrollViewDidEndDecelerating:weakSelf.scrollView];
                if (completion) completion();
            });
        }
    } else {
        viewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
        self.viewController = viewController;
        [self scrollViewDidEndDecelerating:self.scrollView];
        CGFloat width1 = [self visibleWidthOfViewController:self.viewController];
        [self didChangeOffsetForViewController:self.viewController offset:width1 / self.scrollView.width];
        if (completion) completion();
    }
}

// MARK: - UIScrollViewDelegate

- (void)panning:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.swiping = YES;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        if (self.viewController) {
            if (self.secondViewController) {
                CGFloat width2 = [self visibleWidthOfViewController:self.secondViewController];
                if (width2 == 0) {
                    self.swiping = YES;
                    self.secondViewController = nil;
                    [self addViewControllers:self.scrollView];
                } else {
                    CGFloat width1 = [self visibleWidthOfViewController:self.viewController];
                    UIViewController *viewController = width1 > width2 ? self.viewController : self.secondViewController;
                    if (self.viewController != viewController) {
                        _secondViewController = self.viewController;
                        _viewController = viewController;
                        [self didChangeViewController:_viewController];
                    }
                }
            } else {
                [self addViewControllers:self.scrollView];
            }
        }
    }
}

- (void)addViewControllers:(UIScrollView*)scrollView {
    if (!self.swiping) {
        return;
    }
    CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView];
    if (translation.x != 0) {
        self.swiping = NO;
        UIScrollView *scrollView = self.scrollView;
        if (translation.x > 0) {
            UIViewController *viewController = [self viewControllerBeforeViewController:self.viewController];
            if (viewController) {
                self.viewController.view.frame = CGRectMake(scrollView.size.width, 0, scrollView.size.width, scrollView.size.height);
                viewController.view.frame = CGRectMake(0, 0, scrollView.size.width, scrollView.size.height);
                scrollView.contentSize = CGSizeMake(self.scrollView.width * 2, self.scrollView.height);
                scrollView.contentOffset = CGPointMake(self.scrollView.width, 0);
                self.secondViewController = viewController;
            }
        } else {
            UIViewController *viewController = [self viewControllerAfterViewController:self.viewController];
            if (viewController) {
                viewController.view.frame = CGRectMake(scrollView.size.width, 0, scrollView.size.width, scrollView.size.height);
                self.viewController.view.frame = CGRectMake(0, 0, scrollView.size.width, scrollView.size.height);
                scrollView.contentSize = CGSizeMake(self.scrollView.width * 2, self.scrollView.height);
                scrollView.contentOffset = CGPointZero;
                self.secondViewController = viewController;
            }
        }
    }
}

- (NSMutableArray *)viewControllers {
    if (!_viewControllers) {
        _viewControllers = [NSMutableArray array];
    }
    return _viewControllers;
}

- (void)addViewController:(UIViewController*)viewController {
    if (viewController) {
        [self.viewControllers addObject:viewController];
        [self addChildViewController:viewController];
        if (viewController.view.superview != self.scrollView) {
            [self.scrollView addSubview:viewController.view];
        }
    }
}

- (void)removeViewController:(UIViewController*)viewController {
    if (viewController) {
        [self.viewControllers removeObject:viewController];
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
    }
}

- (CGFloat)visibleWidthOfViewController:(UIViewController*)viewController {
    return [self.scrollView visibleRectOfRect:viewController.view.frame].size.width;
}

- (CGFloat)visibleWidthOfViewController:(UIViewController*)viewController withContentOffset:(CGPoint)contentOffset {
    return [self.scrollView visibleRectOfRect:viewController.view.frame withContentOffset:contentOffset].size.width;
}

- (void)setSecondViewController:(UIViewController *)secondViewController {
    if (_secondViewController != secondViewController) {
        [self removeViewController:_secondViewController];
        _secondViewController = secondViewController;
        [self addViewController:secondViewController];
    }
}

- (void)setViewController:(UIViewController *)viewController {
    if (_viewController != viewController) {
        [self removeViewController:_viewController];
        _viewController = viewController;
        [self addViewController:viewController];
        [self didChangeViewController:viewController];
    }
}

- (void)didChangeViewController:(UIViewController *)viewController {
    
}

- (void)didChangeOffsetForViewController:(UIViewController *)viewController offset:(CGFloat)offset {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.viewController) {
        CGFloat width1 = [self visibleWidthOfViewController:self.viewController];
        [self didChangeOffsetForViewController:self.viewController offset:width1 / self.scrollView.width];
    }
    if (self.secondViewController) {
        CGFloat width2 = [self visibleWidthOfViewController:self.secondViewController];
        [self didChangeOffsetForViewController:self.secondViewController offset:width2 / self.scrollView.width];
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGFloat width2 = [self visibleWidthOfViewController:self.secondViewController withContentOffset:*targetContentOffset];
    if (width2 != 0) {
        CGFloat width1 = [self visibleWidthOfViewController:self.viewController withContentOffset:*targetContentOffset];
        UIViewController *currentViewController = width1 > width2 ? self.viewController : self.secondViewController;
        if (self.viewController != currentViewController) {
            _secondViewController = self.viewController;
            _viewController = currentViewController;
            [self didChangeViewController:_viewController];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.viewController.view.x = 0;
    self.secondViewController = nil;
    self.scrollView.contentSize = self.scrollView.size;
    self.scrollView.contentOffset = CGPointZero;
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController != self.viewController) {
            [self removeViewController:viewController];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.viewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.viewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
}

@end
