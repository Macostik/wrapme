//
//  WLWrapCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSObject+NibAdditions.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "UILabel+Additions.h"
#import "UIView+GestureRecognizing.h"
#import "WLCandyCell.h"
#import "WLBasicDataSource.h"
#import "WLNotificationCenter.h"
#import "WLBadgeLabel.h"
#import "WLWrapCell.h"
#import "UIFont+CustomFonts.h"
#import "WLGradientView.h"

@interface WLWrapCell () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *candiesView;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *wrapNotificationLabel;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;

@property (assign, nonatomic) BOOL embeddedLongPress;

@property (strong, nonatomic) WLBasicDataSource* candiesDataSource;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftSwipeActionConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rightSwipeActionConstraint;

@property (weak, nonatomic) NSLayoutConstraint *swipeActionConstraint;

@property (weak, nonatomic) UIPanGestureRecognizer *swipeActionGestureRecognizer;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
    
    if (self.candiesView) {
        WLBasicDataSource* dataSource = [WLBasicDataSource dataSource:self.candiesView];
        dataSource.cellIdentifier = WLCandyCellIdentifier;
        dataSource.selectionBlock = self.selectionBlock;
        dataSource.minimumLineSpacing = WLCandyCellSpacing;
        dataSource.sectionLeftInset = dataSource.sectionRightInset = WLCandyCellSpacing;
        [dataSource setNumberOfItemsBlock:^NSUInteger {
            return ([dataSource.items count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;
        }];
        [dataSource setCellIdentifierForItemBlock:^NSString *(id item, NSUInteger index) {
            return (index < [dataSource.items count]) ? WLCandyCellIdentifier : @"CandyPlaceholderCell";
        }];
        [dataSource setItemSizeBlock:^CGSize(id item, NSUInteger index) {
            int size = (WLConstants.screenWidth - 2.0f)/3.0f;
            return CGSizeMake(size, size);
        }];
        self.candiesDataSource = dataSource;
    }
    [self.coverView setImageName:@"default-small-cover" forState:WLImageViewStateEmpty];
    [self.coverView setImageName:@"default-small-cover" forState:WLImageViewStateFailed];
    
    __weak __typeof(self)weakSelf = self;
    [UILongPressGestureRecognizer recognizerWithView:self block:^(UIGestureRecognizer *recognizer) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            [weakSelf.delegate wrapCell:weakSelf didDeleteWrap:weakSelf.entry];
        }
    }];
    
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

- (void)setSelectionBlock:(WLObjectBlock)selectionBlock {
    [super setSelectionBlock:selectionBlock];
    self.candiesDataSource.selectionBlock = selectionBlock;
}

- (void)setup:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
    self.dateLabel.text = WLString(wrap.updatedAt.timeAgoStringAtAMPM);
    
    if (self.candiesView) {
        self.candiesDataSource.items = [wrap recentCandies:WLHomeTopWrapCandiesLimit];
    }
    
    self.coverView.url = [wrap.picture anyUrl];
    self.wrapNotificationLabel.intValue = [wrap unreadNotificationsCandyCount];
    self.chatButton.hidden = [wrap unreadNotificationsMessageCount] == 0;
}

- (IBAction)notifyChatClick:(id)sender {
    [self.delegate wrapCell:self presentChatViewControllerForWrap:self.entry];
}

// MARK: - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (self.swipeActionGestureRecognizer == panGestureRecognizer) {
        CGPoint velocity = [panGestureRecognizer velocityInView:panGestureRecognizer.view];
        return fabs(velocity.x) > fabs(velocity.y);
    }
    return YES;
}

- (void)panning:(UIPanGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self.delegate wrapCellDidBeginPanning:self];
        self.swipeActionConstraint = [sender locationInView:sender.view].x < self.width/2.0f ? self.leftSwipeActionConstraint : self.rightSwipeActionConstraint;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat constant = self.swipeActionConstraint.constant +  [sender translationInView:sender.view].x;
        if (self.swipeActionConstraint == self.rightSwipeActionConstraint) {
            self.swipeActionConstraint.constant = Smoothstep(-self.width, 0, constant);
        } else {
            self.swipeActionConstraint.constant = Smoothstep(0, self.width, constant);
        }
        [self layoutIfNeeded];
        [sender setTranslation:CGPointZero inView:sender.view];
    } else if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        [self.delegate wrapCellDidEndPanning:self];
        if (ABS(self.swipeActionConstraint.constant) >= 2.0f * self.width / 3.0f) {
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                if (self.swipeActionConstraint == self.rightSwipeActionConstraint) {
                    self.swipeActionConstraint.constant = -self.width;
                } else {
                    self.swipeActionConstraint.constant = self.width;
                }
                [self layoutIfNeeded];
            } completion:^(BOOL finished) {
                if (self.swipeActionConstraint == self.rightSwipeActionConstraint) {
                    [self.delegate wrapCell:self presentChatViewControllerForWrap:self.entry];
                } else {
                    [self.delegate wrapCell:self presentCameraViewControllerForWrap:self.entry];
                }
                run_after_asap(^{
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