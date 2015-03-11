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
#import "NSString+Additions.h"

@interface WLCommentsViewController () <WLEntryNotifyReceiver, UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCommentsViewSection *dataSection;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
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
    self.composeBar.placeholder = WLLS(@"Write your comment ...");
    self.refresher = [WLRefresher refresher:self.collectionView target:self
                                     action:@selector(refresh:)
                                      style:WLRefresherStyleWhite_Clear];
    [self refresh:nil];
    NSArray *entries = [[self.candy.comments reverseObjectEnumerator] allObjects];
    self.dataSection.entries = [NSMutableOrderedSet orderedSetWithArray:entries];
    self.collectionView.layer.geometryFlipped = YES;
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
}

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    if (completion) completion(![self.candy.comments containsObject:entry]);
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
    [self.candy uploadComment:[text trim] success:^(WLComment *comment) {
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
    [fromViewController viewWillDisappear:YES];
    [toViewController viewWillAppear:YES];
    __weak typeof(self)weakSelf = self;
    if (self.isBeingPresented) {
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
                             [fromViewController viewDidDisappear:YES];
                             [toViewController viewDidAppear:YES];
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
                             [fromViewController viewDidDisappear:YES];
                             [toViewController viewDidAppear:YES];
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
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    UICollectionView *collectionView = self.collectionView;
    CGPoint touchPoint = [sender locationInView:collectionView];
    if (CGRectContainsPoint(collectionView.bounds, touchPoint)) {
        [self.view endEditing:YES];
    } else {
        [self onClose:nil];
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
