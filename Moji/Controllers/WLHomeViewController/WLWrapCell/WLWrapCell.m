//
//  WLWrapCell.m
//  moji
//
//  Created by Ravenpod on 20.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSObject+NibAdditions.h"
#import "UILabel+Additions.h"
#import "WLCandyCell.h"
#import "WLBasicDataSource.h"
#import "WLNotificationCenter.h"
#import "WLBadgeLabel.h"
#import "WLWrapCell.h"
#import "UIFont+CustomFonts.h"
#import "WLGradientView.h"
#import "WLWhatsUpSet.h"
#import "UIView+LayoutHelper.h"
#import "WLMessagesCounter.h"
#import "WLWrapStatusImageView.h"

static CGFloat WLWrapCellSwipeActionWidth = 125;

@interface WLWrapCell () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet WLWrapStatusImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet WLBadgeLabel *wrapNotificationLabel;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *chatNotificationLabel;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftSwipeActionConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightSwipeActionConstraint;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *leftSwipeIndicationViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *rightSwipeIndicationViews;

@property (nonatomic) BOOL isRightSwipeAction;

@property (weak, nonatomic) NSLayoutConstraint *swipeActionConstraint;

@property (weak, nonatomic) UIPanGestureRecognizer *swipeActionGestureRecognizer;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
    
    [self.coverView setImageName:@"default-small-cover" forState:WLImageViewStateEmpty];
    [self.coverView setImageName:@"default-small-cover" forState:WLImageViewStateFailed];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panning:)];
    panGestureRecognizer.delegate = self;
    [self.nameLabel.superview addGestureRecognizer:panGestureRecognizer];
    self.swipeActionGestureRecognizer = panGestureRecognizer;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.leftSwipeActionConstraint.constant = 0;
    self.rightSwipeActionConstraint.constant = 0;
}

- (void)setup:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
    self.dateLabel.text = WLString(wrap.updatedAt.timeAgoStringAtAMPM);
    self.coverView.url = [wrap.picture anyUrl];
    self.wrapNotificationLabel.intValue = [[WLWhatsUpSet sharedSet] unreadCandiesCountForWrap:wrap];
    NSUInteger messageConter = [[WLMessagesCounter instance] countForWrap:wrap];
    self.chatNotificationLabel.intValue = messageConter;
    BOOL hasUnreadMessages = messageConter > 0;
    self.chatButton.hidden = !hasUnreadMessages;
    self.nameLabel.horizontallyResistible = !hasUnreadMessages;
    self.chatButton.horizontallyResistible = hasUnreadMessages;
    self.chatNotificationLabel.horizontallyResistible = hasUnreadMessages;
    self.coverView.followed = wrap.isPublic && [wrap.contributors containsObject:[WLUser currentUser]];
}

- (IBAction)notifyChatClick:(id)sender {
    [self.delegate wrapCell:self presentChatViewControllerForWrap:self.entry];
}

// MARK: - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (self.swipeActionGestureRecognizer == panGestureRecognizer) {
        CGPoint velocity = [panGestureRecognizer velocityInView:panGestureRecognizer.view];
        BOOL shouldBegin = fabs(velocity.x) > fabs(velocity.y);
        if (shouldBegin) {
            return [self checkIfActionAllowed:velocity.x < 0];
        }
        return shouldBegin;
    }
    return YES;
}

- (void)setIsRightSwipeAction:(BOOL)isRightSwipeAction {
    _isRightSwipeAction = isRightSwipeAction;
    self.swipeActionConstraint = isRightSwipeAction ? self.rightSwipeActionConstraint : self.leftSwipeActionConstraint;
}

- (BOOL)checkIfActionAllowed:(BOOL)isRightSwipeAction {
    WLWrap *wrap = self.entry;
    if (!wrap.isPublic) return YES;
    if ([wrap.contributors containsObject:[WLUser currentUser]]) return !isRightSwipeAction;
    return NO;
}

- (void)panning:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.delegate wrapCellDidBeginPanning:self];
        self.isRightSwipeAction = [sender velocityInView:sender.view].x < 0;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat constant = self.swipeActionConstraint.constant + [sender translationInView:sender.view].x;
        if (self.isRightSwipeAction) {
            self.swipeActionConstraint.constant = Smoothstep(-self.width, 0, constant);
            for (UIView *indicationView in self.rightSwipeIndicationViews) {
                indicationView.alpha = NSmoothstep(ABS(self.swipeActionConstraint.constant)/WLWrapCellSwipeActionWidth);
            }
        } else {
            self.swipeActionConstraint.constant = Smoothstep(0, self.width, constant);
            for (UIView *indicationView in self.leftSwipeIndicationViews) {
                indicationView.alpha = NSmoothstep(ABS(self.swipeActionConstraint.constant)/WLWrapCellSwipeActionWidth);
            }
        }
        [self layoutIfNeeded];
        [sender setTranslation:CGPointZero inView:sender.view];
        
    } else if ((sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled)) {
        BOOL performedAction = ABS(self.swipeActionConstraint.constant) >= WLWrapCellSwipeActionWidth;
        [self.delegate wrapCellDidEndPanning:self performedAction:performedAction];
        if (performedAction) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                self.swipeActionConstraint.constant = self.isRightSwipeAction ? -self.width : self.width;
                [self layoutIfNeeded];
            } completion:^(BOOL finished) {
                if (self.isRightSwipeAction) {
                    [self.delegate wrapCell:self presentChatViewControllerForWrap:self.entry];
                } else {
                    [self.delegate wrapCell:self presentCameraViewControllerForWrap:self.entry];
                }
                run_after(0.5f, ^{
                    self.swipeActionConstraint.constant = 0;
                    [self setNeedsLayout];
                });
            }];
        } else {
            if (self.swipeActionConstraint.constant != 0) {
                [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.swipeActionConstraint.constant = 0;
                    [self layoutIfNeeded];
                } completion:^(BOOL finished) {
                }];
            }
        }
    }
}

@end