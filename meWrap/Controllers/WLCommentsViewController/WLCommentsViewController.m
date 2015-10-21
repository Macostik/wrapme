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
#import "StreamDataSource.h"
#import "WLSoundPlayer.h"
#import "WLNavigationHelper.h"
#import "UIFont+CustomFonts.h"
#import "WLDeviceManager.h"
#import "WLCommentCell.h"
#import "WLStreamLoadingView.h"
#import "WLEntry+WLUploadingQueue.h"
#import "WLComposerScrollView.h"
#import "WLHistoryViewController.h"

static CGFloat WLNotificationCommentHorizontalSpacing = 84.0f;
static CGFloat WLNotificationCommentVerticalSpacing = 24.0f;

@interface WLCommentsViewController () <UIViewControllerTransitioningDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *composeBarBottomPrioritizer;
@property (weak, nonatomic) IBOutlet WLComposerScrollView *contentView;
@property (weak, nonatomic) WLHistoryViewController *historyViewController;

@end

@implementation WLCommentsViewController

- (void)viewDidLoad {
    
    __weak typeof(self)weakSelf = self;
    
    __weak StreamView *streamView = self.dataSource.streamView;
    
    [super viewDidLoad];
    
    if  (!self.candy.valid) return;
    
    self.dataSource.autogeneratedMetrics.selectable = NO;
    [self.dataSource.autogeneratedMetrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        WLComment *comment = [weakSelf.dataSource.items tryAt:position.index];
        UIFont *font = [UIFont preferredDefaultFontWithPreset:WLFontPresetNormal];
        UIFont *nameFont = [UIFont preferredDefaultLightFontWithPreset:WLFontPresetNormal];
        UIFont *timeFont = [UIFont preferredDefaultLightFontWithPreset:WLFontPresetSmall];
        CGFloat textHeight = [comment.text heightWithFont:font width:streamView.width - WLNotificationCommentHorizontalSpacing];
        return MAX(72, textHeight + nameFont.lineHeight + timeFont.lineHeight + WLNotificationCommentVerticalSpacing);
    }];
 
    [self.dataSource setDidLayoutBlock:^{
        [weakSelf.dataSource.streamView setMaximumContentOffsetAnimated:NO];
    }];
    
    self.dataSource.items = [self sortedComments];
    
    run_after_asap(^{
        weakSelf.dataSource.didLayoutBlock = nil;
    });
    
    if (self.candy.uploaded) {
        [self.candy fetch:^(id object) {
            weakSelf.dataSource.items = [weakSelf sortedComments];
        } failure:^(NSError *error) {
            [weakSelf.dataSource reload];
            [error showIgnoringNetworkError];
        }];
    }
    
    [self addNotifyReceivers];
    [[WLDeviceManager manager] addReceiver:self];
    self.historyViewController = (WLHistoryViewController *)self.parentViewController;
}

- (NSMutableOrderedSet *)sortedComments {
    return [[self.candy sortedComments] mutableCopy];
}

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    if (completion) completion(![self.candy.comments containsObject:entry]);
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
    [self.historyViewController viewWillAppear:YES];
    [self removeFromContainerAnimated:YES];
    [self.historyViewController applyScaleToCandyViewController:NO];
}

- (IBAction)hide:(UITapGestureRecognizer *)sender {
    UIView *contentView = self.dataSource.streamView.superview;
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
        receiver.willDeleteBlock = ^(WLComment *comment) {
            weakSelf.dataSource.items = [(NSMutableOrderedSet*)weakSelf.dataSource.items remove:comment];
        };
        receiver.didUpdateBlock = receiver.didAddBlock = ^(WLComment *comment) {
            weakSelf.dataSource.items = [weakSelf sortedComments];
        };
    }];
    
    [WLCandy notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        [receiver setEntryBlock:^WLEntry *{
            return weakSelf.candy;
        }];
        [receiver setContainerBlock:^WLEntry *{
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

#pragma mark - WLKeyboardBroadcastReceiver

static CGFloat WLContstraintOffset = 44.0;

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight - WLContstraintOffset;
}

#pragma mark - WLDeviceManager

- (void)manager:(WLDeviceManager*)manager didChangeOrientation:(NSNumber*)orientation {
    [self.view layoutIfNeeded];
    [self.dataSource reload];
}

// MARK: - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL direction = [scrollView.panGestureRecognizer translationInView:scrollView.superview].y < 0;
    self.composeBarBottomPrioritizer.defaultState = direction;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    CGPoint offset = scrollView.contentOffset;
    if (ABS(offset.y) > scrollView.height/5 || ABS(velocity.y) > 2) {
        UIView *snapshot = [self.contentView snapshotViewAfterScreenUpdates:NO];
        snapshot.frame = CGRectMake(0, self.contentView.y, self.view.width, self.contentView.height);
        [self.view.window addSubview:snapshot];
        [self removeFromContainerAnimated:YES];
        [UIView animateWithDuration:0.5 animations:^{
            CGFloat offsetY = offset.y > 0 ? self.view.y - self.view.height : self.view.height;
            snapshot.transform = CGAffineTransformMakeTranslation(0, offsetY);
            [self.historyViewController applyScaleToCandyViewController:NO];
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
        }];
    } 
}

- (void)presentForController:(UIViewController *)controller animated:(BOOL)animated {
    [controller addContainedViewController:self animated:animated];
    self.contentView.transform = CGAffineTransformMakeTranslation(0, CGRectGetMaxY(self.view.frame));
    [UIView animateWithDuration:0.5f
                          delay:0.0f
         usingSpringWithDamping:0.7f
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.contentView.transform = CGAffineTransformIdentity;
    }               completion:nil];
}

@end
