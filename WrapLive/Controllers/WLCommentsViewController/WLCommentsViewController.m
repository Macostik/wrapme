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
#import "WLBasicDataSource.h"
#import "WLSoundPlayer.h"
#import "UIView+AnimationHelper.h"
#import "WLNavigationHelper.h"
#import "UIFont+CustomFonts.h"

static CGFloat WLNotificationCommentHorizontalSpacing = 80.0f;
static CGFloat WLNotificationCommentVerticalSpacing = 67.0f;
static CGFloat WLTextViewInsets = 10.0f;

@interface WLCommentsViewController () <UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (strong, nonatomic) WLRefresher *refresher;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topCommentViewContstrain;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingContstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingConstraint;

@end

@implementation WLCommentsViewController

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if  (!self.candy.valid) return;
    self.composeBar.placeholder = WLLS(@"Write your comment ...");
    self.refresher = [WLRefresher refresher:self.collectionView target:self
                                     action:@selector(refresh:)
                                      style:WLRefresherStyleWhite_Clear];
    [self refresh:nil];
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setItemSizeBlock:^CGSize(WLComment *comment, NSUInteger index) {
        CGFloat textHeight = [comment.text heightWithFont:[UIFont preferredFontWithName:WLFontOpenSansLight preset:WLFontPresetSmall]
                                                    width:weakSelf.collectionView.width - WLNotificationCommentHorizontalSpacing - WLTextViewInsets];
        return CGSizeMake(weakSelf.collectionView.width, textHeight + WLNotificationCommentVerticalSpacing);
    }];
    
    self.dataSource.items = [self.candy sortedComments];
    self.collectionView.layer.geometryFlipped = YES;
    [self addNotifyReceivers];
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
    if (self.candy.valid) {
        [WLSoundPlayer playSound:WLSound_s04];
        [self.candy uploadComment:[text trim] success:^(WLComment *comment) {
        } failure:^(NSError *error) {
        }];
    }
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
    UIView *contentView = self.collectionView.superview;
    CGPoint touchPoint = [sender locationInView:contentView];
    if (CGRectContainsPoint(contentView.bounds, touchPoint)) {
        [self.view endEditing:YES];
    } else {
        [self onClose:nil];
    }
}

#pragma mark - WLEntryNotifyReceiver

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    
    [WLComment notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.candy;
        }];
        [receiver setAddedBlock:^(WLComment *comment) {
            weakSelf.dataSource.items = [weakSelf.candy sortedComments];
        }];
        receiver.deletedBlock = receiver.updatedBlock = receiver.addedBlock;
    }];
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.candy;
        }];
        [receiver setDeletedBlock:^(WLCandy *candy) {
            [weakSelf onClose:nil];
        }];
    }];
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.candy.wrap;
        }];
        [receiver setDeletedBlock:^(WLWrap *wrap) {
            [weakSelf onClose:nil];
        }];
    }];
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

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight - WLContstraintOffset;
}

#pragma mark - InterfaceOrientations

- (NSUInteger)supportedInterfaceOrientations {
    [self.collectionView.collectionViewLayout invalidateLayout];
    return UIInterfaceOrientationMaskAll;
}

@end
