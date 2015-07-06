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
#import "UIView+Extentions.h"
#import "WLDeviceOrientationBroadcaster.h"
#import "WLCommentCell.h"
#import "WLLoadingView.h"

static CGFloat WLNotificationCommentHorizontalSpacing = 84.0f;
static CGFloat WLNotificationCommentVerticalSpacing = 69.0f;

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

- (void)viewDidLoad {
    
    UICollectionView *collectionView = self.dataSource.collectionView;
    
    [WLLoadingView registerInCollectionView:collectionView];
    self.dataSource.footerIdentifier = @"WLLoadingView";
    
    self.dataSource.footerSize = CGSizeMake(collectionView.width, WLLoadingViewDefaultSize);
    
    self.collectionView.layer.geometryFlipped = YES;
    
    [super viewDidLoad];
    
    if  (!self.candy.valid) return;
    
    
    
    self.composeBar.placeholder = WLLS(@"comment_placeholder");
    self.refresher = [WLRefresher refresher:collectionView target:self
                                     action:@selector(refresh:)
                                      style:WLRefresherStyleWhite_Clear];
    [self refresh:nil];
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setItemSizeBlock:^CGSize(WLComment *comment, NSUInteger index) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        UIFont *font = [UIFont preferredFontWithName:WLFontOpenSansRegular preset:WLFontPresetNormal];
        paragraphStyle.firstLineHeadIndent = [[weakSelf.candy contributor] isCurrentUser] ? WLLineHeadIndent : 0;
        NSAttributedString *attributedText = [[NSAttributedString alloc]initWithString:comment.text
                                                                            attributes: @{NSParagraphStyleAttributeName : paragraphStyle,
                                                                                          NSFontAttributeName : font}];
        CGFloat textHeight = [attributedText heightForDefautWidth:collectionView.width - WLNotificationCommentHorizontalSpacing];
        return CGSizeMake(collectionView.width, textHeight + WLNotificationCommentVerticalSpacing);
    }];
 
    self.dataSource.items = [self sortedComments];
    [self addNotifyReceivers];
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
}

- (NSMutableOrderedSet *)sortedComments {
    return [[self.candy sortedComments] mutableCopy];
}

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    if (completion) completion(![self.candy.comments containsObject:entry]);
}

- (void)refresh:(WLRefresher*)sender {
    __weak typeof(self)weakSelf = self;
    if (self.candy.uploaded) {
        [self.candy fetch:^(id object) {
            weakSelf.dataSource.footerSize = CGSizeZero;
            weakSelf.dataSource.items = [weakSelf sortedComments];
            [sender setRefreshing:NO animated:YES];
        } failure:^(NSError *error) {
            weakSelf.dataSource.footerSize = CGSizeZero;
            [error showIgnoringNetworkError];
            [sender setRefreshing:NO animated:YES];
        }];
    } else {
        [sender setRefreshing:NO animated:YES];
    }
}

- (void)presentAsChildForParentViewController:(UIViewController *)parentViewContrller {
    self.view.frame = parentViewContrller.view.bounds;
    [parentViewContrller.view addSubview:self.view];
    [parentViewContrller addChildViewController:self];
    [self didMoveToParentViewController:parentViewContrller];
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

- (IBAction)onClose:(id)sender {
    [self.view endEditing:YES];
    [self.view removeFromSuperview];
    [self.parentViewController viewWillAppear:YES];
    [self removeFromParentViewController];
}

- (IBAction)hide:(UITapGestureRecognizer *)sender {
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
        [receiver setShouldNotifyBlock:^BOOL(WLComment *comment) {
            NSMutableOrderedSet *comments = (NSMutableOrderedSet*)weakSelf.dataSource.items;
            return comment.candy == weakSelf.candy || [comments containsObject:comment];
        }];
        receiver.didDeleteBlock = receiver.didUpdateBlock = receiver.didAddBlock = ^(WLComment *comment) {
            weakSelf.dataSource.items = [weakSelf sortedComments];
        };
    }];
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.candy;
        }];
        [receiver setContainingEntryBlock:^WLEntry *{
            return weakSelf.candy.wrap;
        }];
        receiver.willDeleteContainingBlock = receiver.willDeleteBlock = ^(WLCandy *candy) {
            [weakSelf onClose:nil];
        };
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

#pragma mark - WLDeviceOrientationBroadcaster

- (void)broadcaster:(WLDeviceOrientationBroadcaster*)broadcaster didChangeOrientation:(NSNumber*)orientation {
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
