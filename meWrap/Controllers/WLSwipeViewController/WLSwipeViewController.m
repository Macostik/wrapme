//
//  WLSwipeViewController.m
//  meWrap
//
//  Created by Ravenpod on 5/7/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLSwipeViewController.h"

typedef NS_ENUM(NSUInteger, WLSwipeViewControllerPosition) {
    WLSwipeViewControllerPositionCenter,
    WLSwipeViewControllerPositionLeft,
    WLSwipeViewControllerPositionRight,
};

@interface WLSwipeViewController () <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView* scrollView;

@property (weak, nonatomic) UIViewController *secondViewController;

@property (nonatomic) WLSwipeViewControllerPosition position;

@end

@implementation WLSwipeViewController

- (void)dealloc {
    self.scrollView.delegate = nil;
}

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

- (void)setViewController:(UIViewController*)viewController direction:(WLSwipeViewControllerDirection)direction animated:(BOOL)animated completion:(Block)completion {
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
            [[Dispatch mainQueue] after:0.5 block:^{
                [weakSelf scrollViewDidEndDecelerating:weakSelf.scrollView];
                if (completion) completion();
            }];
        } else {
            self.secondViewController = self.viewController;
            self.secondViewController.view.frame = CGRectMake(self.scrollView.size.width, 0, self.scrollView.size.width, self.scrollView.size.height);
            _viewController = nil;
            self.viewController = viewController;
            self.viewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
            self.scrollView.contentSize = CGSizeMake(self.scrollView.width * 2, self.scrollView.height);
            self.scrollView.contentOffset = CGPointMake(self.scrollView.width, 0);
            [self.scrollView setContentOffset:CGPointZero animated:YES];
            [[Dispatch mainQueue] after:0.5 block:^{
                [weakSelf scrollViewDidEndDecelerating:weakSelf.scrollView];
                if (completion) completion();
            }];
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

- (void)setPosition:(WLSwipeViewControllerPosition)position {
    if (_position != position) {
        _position = position;
        UIScrollView *scrollView = self.scrollView;
        if (position == WLSwipeViewControllerPositionLeft) {
            UIViewController *viewController = [self viewControllerBeforeViewController:self.viewController];
            if (viewController) {
                self.viewController.view.frame = CGRectMake(scrollView.size.width, 0, scrollView.size.width, scrollView.size.height);
                viewController.view.frame = CGRectMake(0, 0, scrollView.size.width, scrollView.size.height);
                scrollView.contentSize = CGSizeMake(self.scrollView.width * 2, self.scrollView.height);
                scrollView.contentOffset = CGPointMake(self.scrollView.width, 0);
                self.secondViewController = viewController;
            }
        } else if (position == WLSwipeViewControllerPositionRight) {
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

- (void)panning:(UIPanGestureRecognizer*)sender {
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        _position = WLSwipeViewControllerPositionCenter;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        if (self.viewController) {
            
            CGFloat offset = self.scrollView.contentOffset.x - self.viewController.view.x;
            if (offset < 0) {
                self.position = WLSwipeViewControllerPositionLeft;
            } else if (offset > 0) {
                self.position = WLSwipeViewControllerPositionRight;
            } else {
                self.position = WLSwipeViewControllerPositionCenter;
            }
            
            [self swapViewControllersIfNeededWithContentOffset:self.scrollView.contentOffset];
        }
    }
}

- (void)addViewController:(UIViewController*)viewController {
    if (viewController) {
        [self addChildViewController:viewController];
        if (viewController.view.superview != self.scrollView) {
            [self.scrollView addSubview:viewController.view];
        }
    }
}

- (void)removeViewController:(UIViewController*)viewController {
    if (viewController) {
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
    }
}

- (CGFloat)visibleWidthOfViewController:(UIViewController*)viewController {
    return [self.scrollView visibleRectOfRect:viewController.view.frame].size.width;
}

- (CGFloat)visibleWidthOfViewController:(UIViewController*)viewController withContentOffset:(CGPoint)contentOffset {
    return [self.scrollView visibleRectOfRect:viewController.view.frame offset:contentOffset].size.width;
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

- (void)swapViewControllersIfNeededWithContentOffset:(CGPoint)contentOffset {
    if (self.secondViewController) {
        CGFloat width2 = [self visibleWidthOfViewController:self.secondViewController withContentOffset:contentOffset];
        if (width2 != 0) {
            CGFloat width1 = [self visibleWidthOfViewController:self.viewController withContentOffset:contentOffset];
            UIViewController *currentViewController = width1 > width2 ? self.viewController : self.secondViewController;
            if (self.viewController != currentViewController) {
                _secondViewController = self.viewController;
                _viewController = currentViewController;
                if (self.position == WLSwipeViewControllerPositionRight) {
                    _position = WLSwipeViewControllerPositionLeft;
                } else if (self.position == WLSwipeViewControllerPositionLeft) {
                    _position = WLSwipeViewControllerPositionRight;
                }
                [self didChangeViewController:_viewController];
            }
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    [self swapViewControllersIfNeededWithContentOffset:*targetContentOffset];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.viewController.view.x = 0;
    self.secondViewController = nil;
    self.scrollView.contentSize = self.scrollView.size;
    self.scrollView.contentOffset = CGPointZero;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.viewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    self.viewController.view.frame = CGRectMake(0, 0, self.scrollView.size.width, self.scrollView.size.height);
}

@end
