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

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *candiesView;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *wrapNotificationLabel;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet WLGradientView *handlerSwipeView;

@property (assign, nonatomic) BOOL embeddedLongPress;

@property (strong, nonatomic) WLBasicDataSource* candiesDataSource;

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
            if  ([weakSelf.delegate respondsToSelector:@selector(wrapCell:didDeleteWrap:)])
                [weakSelf.delegate wrapCell:weakSelf didDeleteWrap:weakSelf.entry];
        }
    }];
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
    if ([self.delegate respondsToSelector:@selector(wrapCell:forWrap:notifyChatButtonClicked:)])
        [self.delegate wrapCell:self forWrap:self.entry notifyChatButtonClicked:sender];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (ABS(scrollView.contentOffset.x) > self.handlerSwipeView.width/2) {
        if (scrollView.contentOffset.x > 0.0f) {
            if ([self.delegate respondsToSelector:@selector(wrapCell:forWrap:presentChatViewController:)])
                [self.delegate wrapCell:self forWrap:self.entry presentChatViewController:scrollView];
        } else {
            if ([self.delegate respondsToSelector:@selector(wrapCell:forWrap:presentCameraViewController:)])
                [self.delegate wrapCell:self forWrap:self.entry presentCameraViewController:scrollView];
        }
    }
}

@end