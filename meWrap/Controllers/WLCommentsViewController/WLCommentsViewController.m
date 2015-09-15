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
#import "UIView+AnimationHelper.h"
#import "WLNavigationHelper.h"
#import "UIFont+CustomFonts.h"
#import "UIView+Extentions.h"
#import "WLDeviceOrientationBroadcaster.h"
#import "WLCommentCell.h"
#import "WLStreamLoadingView.h"
#import "UIScrollView+Additions.h"

static CGFloat WLNotificationCommentHorizontalSpacing = 84.0f;
static CGFloat WLNotificationCommentVerticalSpacing = 24.0f;

@interface WLCommentsViewController () <UIViewControllerTransitioningDelegate>

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

@end

@implementation WLCommentsViewController

- (void)viewDidLoad {
    
    __weak typeof(self)weakSelf = self;
    
    __weak StreamView *streamView = self.dataSource.streamView;
    
    [super viewDidLoad];
    
    if  (!self.candy.valid) return;
    
    self.composeBar.placeholder = WLLS(@"comment_placeholder");
    
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
        StreamMetrics *loadingMetrics = [self.dataSource addFooterMetrics:[WLStreamLoadingView streamLoadingMetrics]];
        [self.candy fetch:^(id object) {
            loadingMetrics.hidden = YES;
            weakSelf.dataSource.items = [weakSelf sortedComments];
        } failure:^(NSError *error) {
            loadingMetrics.hidden = YES;
            [weakSelf.dataSource reload];
            [error showIgnoringNetworkError];
        }];
    }
    
    [self addNotifyReceivers];
    [[WLDeviceOrientationBroadcaster broadcaster] addReceiver:self];
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
    [self.parentViewController viewWillAppear:YES];
    [self removeFromParentViewController];
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
        receiver.didDeleteBlock = receiver.didUpdateBlock = receiver.didAddBlock = ^(WLComment *comment) {
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

#pragma mark - WLDeviceOrientationBroadcaster

- (void)broadcaster:(WLDeviceOrientationBroadcaster*)broadcaster didChangeOrientation:(NSNumber*)orientation {
    [self.view layoutIfNeeded];
    [self.dataSource reload];
}

@end
