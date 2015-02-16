//
//  WLCommentsViewController.m
//  
//
//  Created by Yura Granchenko on 28/01/15.
//
//

#import "WLCommentsViewController.h"
#import "WLCandyViewController.h"
#import "WLComposeBar.h"
#import "WLRefresher.h"
#import "WLEntryNotifier.h"
#import "WLAPIManager.h"
#import "WLCommentsViewSection.h"
#import "WLCollectionViewDataProvider.h"
#import "WLCollectionViewFlowLayout.h"
#import "WLSoundPlayer.h"
#import "UIView+AnimationHelper.h"
#import "WLNavigation.h"
#import "WLCollectionView.h"

@interface WLCommentsViewController () <WLEntryNotifyReceiver, UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCommentsViewSection *dataSection;
@property (weak, nonatomic) IBOutlet WLCollectionView *collectionView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (strong, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topCommentViewContstrain;

@end

@implementation WLCommentsViewController

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.composeBar.placeholder = @"Write your comment ...";
    self.refresher = [WLRefresher refresher:self.collectionView target:self
                                     action:@selector(refresh:)
                                      style:WLRefresherStyleWhite_Clear];
    [self refresh:nil];
    NSArray *entries = [[self.candy.comments reverseObjectEnumerator] allObjects];
    self.dataSection.entries = [NSMutableOrderedSet orderedSetWithArray:entries];
    self.collectionView.transform = CGAffineTransformMakeRotation(M_PI);
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
}

- (void)refresh:(WLRefresher*)sender {
    if (self.candy.uploaded) {
        [self.candy fetch:^(id object) {
            [sender setRefreshing:NO animated:YES];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
            [sender setRefreshing:NO animated:YES];
        }];
    } else {
        [sender setRefreshing:NO animated:YES];
    }
}

- (void)sendMessageWithText:(NSString*)text {
    [WLSoundPlayer playSound:WLSound_s04];
    [self.candy uploadComment:text success:^(WLComment *comment) {
    } failure:^(NSError *error) {
    }];
    run_after(.0, ^{
        [self onClose:nil];
    });
}

#pragma mark - Base method override

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    __weak typeof(self)weakSelf = self;
    if (self.isBeingPresented) {
        fromViewController.view.userInteractionEnabled = NO;
        toViewController.view.frame = fromViewController.view.frame;
        [transitionContext.containerView addSubview:toViewController.view];
        self.contentView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        self.view.backgroundColor = [UIColor clearColor];
        [UIView animateWithDuration:1.f
                              delay:0
             usingSpringWithDamping:0.5
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             weakSelf.contentView.transform = CGAffineTransformIdentity;
                             weakSelf.view.backgroundColor = [UIColor colorWithWhite:.0 alpha:0.5];
                         } completion:^(BOOL finished) {
                             [transitionContext completeTransition:YES];
                             fromViewController.view.userInteractionEnabled = YES;
                         }];
    } else {
        [UIView animateWithDuration:0.5f
                              delay:0
             usingSpringWithDamping:1.0
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             weakSelf.contentView.alpha = .0f;
                             weakSelf.view.backgroundColor = [UIColor clearColor];
                         } completion:^(BOOL finished) {
                             weakSelf.contentView.transform = CGAffineTransformIdentity;
                             [transitionContext completeTransition:YES];
                         }];
    }
}

- (void)addEmbeddingConstraintsToContentView:(UIView *)contentView inView:(UIView *)view {
    [view addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                     attribute:NSLayoutAttributeTop
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view
                                                     attribute:NSLayoutAttributeTop
                                                    multiplier:1
                                                      constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                     attribute:NSLayoutAttributeLeading
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view
                                                     attribute:NSLayoutAttributeLeading
                                                    multiplier:1
                                                      constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1
                                                      constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:contentView
                                                     attribute:NSLayoutAttributeBottom
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:view
                                                     attribute:NSLayoutAttributeBottom
                                                    multiplier:1
                                                      constant:0]];
}

- (IBAction)onClose:(id)sender {
    [self.view endEditing:YES];
    id candyViewController = [UINavigationController topViewController];
    if ([candyViewController respondsToSelector:@selector(movingDetailViews)]) {
        [candyViewController movingDetailViews];
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    UICollectionView *collectionView = self.collectionView;
    CGPoint touchPoint = [sender locationInView:collectionView];
    if (!CGRectContainsPoint(collectionView.superview.bounds, touchPoint)) {
        [self onClose:nil];
    } else {
        [self.view endEditing:YES];
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier*)notifier candyUpdated:(WLComment *)comment {
    NSArray *entries = [[self.candy.comments reverseObjectEnumerator] allObjects];
    self.dataSection.entries = [NSMutableOrderedSet orderedSetWithArray:entries];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self onClose:nil];
}

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment {
    NSArray *entries = [[self.candy.comments reverseObjectEnumerator] allObjects];
    self.dataSection.entries = [NSMutableOrderedSet orderedSetWithArray:entries];
}

- (void)notifier:(WLEntryNotifier*)notifier commentDeleted:(WLComment *)comment {
    NSMutableOrderedSet* entries = self.dataSection.entries.entries;
    if ([entries containsObject:comment]) {
        [entries removeObject:comment];
        [self.dataSection reload];
    }
}

- (WLCandy *)notifierPreferredCandy:(WLEntryNotifier *)notifier {
    return self.candy;
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    [self sendMessageWithText:text];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
    return NO;
}

- (void)composeBarDidBeginEditing:(WLComposeBar*)composeBar {
    [self hideTopView:YES];
}

- (void)composeBarDidEndEditing:(WLComposeBar*)composeBar {
    [self hideTopView:NO];
}

- (void)hideTopView:(BOOL)hide {
    [UIView performAnimated:YES animation:^{
        self.topCommentViewContstrain.constant = hide ? 20.0f : WLContstraintOffset;
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - WLKeyboardBroadcastReceiver

static CGFloat WLContstraintOffset = 44.0;

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight - WLContstraintOffset;
}

#pragma mark - InterfaceOrientations

- (NSUInteger)supportedInterfaceOrientations {
    [self.collectionView.collectionViewLayout invalidateLayout];
    return UIInterfaceOrientationMaskAll;
}

@end
