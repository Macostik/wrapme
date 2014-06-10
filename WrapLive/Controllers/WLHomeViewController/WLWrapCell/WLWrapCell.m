//
//  WLWrapCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCell.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "WLImageFetcher.h"
#import "UIView+Shorthand.h"
#import "UILabel+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "WLWrapBroadcaster.h"
#import "WLUser.h"
#import "UIActionSheet+Blocks.h"
#import "StreamView.h"
#import "WLCandyCell.h"
#import "WLUploadingQueue.h"
#import "UIView+GestureRecognizing.h"
#import "WLEntryState.h"

@interface WLWrapCell () <WLCandyCellDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
	__weak typeof(self)weakSelf = self;
	[self.nameLabel.superview addLongPressGestureRecognizing:^(CGPoint point) {
        BOOL showMenu = YES;
        if ([weakSelf.delegate respondsToSelector:@selector(wrapCellShouldShowMenu:)]) {
            showMenu = [weakSelf.delegate wrapCellShouldShowMenu:self];
        }
        if (showMenu) {
            [weakSelf showMenu:point];
        }
	}];
}

- (void)setupItemData:(WLWrap*)wrap {
	self.nameLabel.superview.userInteractionEnabled = YES;
	self.nameLabel.text = wrap.name;
	[self.nameLabel sizeToFitWidthWithSuperviewRightPadding:50];
	self.notifyBulb.x = self.nameLabel.right + 6;
	self.coverView.url = wrap.picture.small;
	self.contributorsLabel.text = wrap.contributorNames;
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
	[self updateNotifyBulbWithWrap:wrap];
}

- (void)updateNotifyBulbWithWrap:(WLWrap *)wrap {
	__weak typeof(self)weakSelf = self;
	[wrap getState:^(BOOL read, BOOL updated) {
		weakSelf.notifyBulb.hidden = read && !updated;
	}];
}

- (void)setCandies:(NSArray *)candies {
	_candies = candies;
	[self.streamView reloadData];
}

- (IBAction)wrapSelected:(UIButton *)sender {
	self.notifyBulb.hidden = YES;
	WLWrap* wrap = self.item;
	[wrap setRead:YES updated:NO];
	if ([UIMenuController sharedMenuController].menuVisible) {
		[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	}
    if ([self.delegate respondsToSelector:@selector(wrapCell:didSelectWrap:)]) {
        [self.delegate wrapCell:self didSelectWrap:self.item];
    }
}

- (void)showMenu:(CGPoint)point {
	UIMenuItem* menuItem = nil;
	__weak typeof(self)weakSelf = self;
	WLWrap* wrap = weakSelf.item;
	if ([wrap.contributor isCurrentUser]) {
		menuItem = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(remove)];
	} else {
		menuItem = [[UIMenuItem alloc] initWithTitle:@"Leave" action:@selector(leave)];
	}
	UIMenuController* menuController = [UIMenuController sharedMenuController];
	[self becomeFirstResponder];
	menuController.menuItems = @[menuItem];
	[menuController setTargetRect:CGRectMake(point.x, [self.reuseIdentifier isEqualToString:@"WLTopWrapCell"] ? point.y + 12 : point.y, 0, 0) inView:self];
	[menuController setMenuVisible:YES animated:YES];
}

- (void)remove {
	__weak typeof(self)weakSelf = self;
	WLWrap* wrap = weakSelf.item;
	weakSelf.userInteractionEnabled = NO;
	[wrap remove:^(id object) {
		weakSelf.userInteractionEnabled = YES;
        if ([weakSelf.delegate respondsToSelector:@selector(wrapCell:didDeleteOrLeaveWrap:)]) {
            [weakSelf.delegate wrapCell:weakSelf didDeleteOrLeaveWrap:wrap];
        }
	} failure:^(NSError *error) {
		[error show];
		weakSelf.userInteractionEnabled = YES;
	}];
}

- (void)leave {
	__weak typeof(self)weakSelf = self;
	WLWrap* wrap = weakSelf.item;
	weakSelf.userInteractionEnabled = NO;
	[wrap leave:^(id object) {
		weakSelf.userInteractionEnabled = YES;
        if ([weakSelf.delegate respondsToSelector:@selector(wrapCell:didDeleteOrLeaveWrap:)]) {
            [weakSelf.delegate wrapCell:weakSelf didDeleteOrLeaveWrap:wrap];
        }
	} failure:^(NSError *error) {
		[error show];
		weakSelf.userInteractionEnabled = YES;
	}];
}

- (BOOL)canPerformAction:(SEL)selector withSender:(id) sender {
	return (selector == @selector(remove)) || (selector == @selector(leave));
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - StreamViewDelegate

- (NSInteger)streamViewNumberOfColumns:(StreamView *)streamView {
	return 3;
}

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section {
	return ([self.candies count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;;
}

- (UIView*)streamView:(StreamView*)streamView viewForItem:(StreamLayoutItem*)item {
	if (item.index.row < [self.candies count]) {
		WLCandyCell* candyView = [streamView reusableViewOfClass:[WLCandyCell class]
															 forItem:item
														 loadingType:StreamViewReusableViewLoadingTypeNib];
		candyView.item = [self.candies objectAtIndex:item.index.row];
		candyView.wrap = self.item;
		candyView.delegate = self;
		return candyView;
	} else {
		UIImageView * placeholderView = [streamView reusableViewOfClass:[UIImageView class]
																forItem:item
															loadingType:StreamViewReusableViewLoadingTypeInit];
		placeholderView.image = [UIImage imageNamed:@"ic_photo_placeholder"];
		placeholderView.contentMode = UIViewContentModeCenter;
		return placeholderView;
	}
}

- (CGFloat)streamView:(StreamView*)streamView ratioForItemAtIndex:(StreamIndex)index {
	return 1;
}

- (void)streamView:(StreamView *)streamView didSelectItem:(StreamLayoutItem *)item {
	if (item.index.row >= [self.candies count]) {
		[self.delegate wrapCellDidSelectCandyPlaceholder:self];
	}
}

#pragma mark - WLWrapCandyCellDelegate

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy {
	[self.delegate wrapCell:self didSelectCandy:candy];
}

@end