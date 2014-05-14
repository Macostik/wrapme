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
#import "UIImageView+ImageLoading.h"
#import "UIView+Shorthand.h"
#import "UILabel+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "WLWrapBroadcaster.h"
#import "WLUser.h"
#import "UIActionSheet+Blocks.h"
#import "StreamView.h"
#import "WLWrapCandyCell.h"
#import "WLUploadingQueue.h"
#import "UIView+GestureRecognizing.h"

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet StreamView *streamView;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
	__weak typeof(self)weakSelf = self;
	[self.nameLabel.superview addLongPressGestureRecognizing:^(CGPoint point){
		[weakSelf showMenu:point];
	}];
}

- (void)setupItemData:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
	self.coverView.imageUrl = wrap.picture.small;
	self.contributorsLabel.text = wrap.contributorNames;
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
	self.nameLabel.superview.vibrateOnLongPressGesture = [wrap.contributor isCurrentUser];
}

- (void)setCandies:(NSArray *)candies {
	_candies = candies;
	[self.streamView reloadData];
}

- (IBAction)wrapSelected:(UIButton *)sender {
	[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	[self.delegate wrapCell:self didSelectWrap:self.item];
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
	} failure:^(NSError *error) {
		[error show];
		weakSelf.userInteractionEnabled = YES;
	}];
}

- (void)leave {
	__weak typeof(self)weakSelf = self;
	WLWrap* wrap = weakSelf.item;
	[UIActionSheet showWithCondition:@"Are you sure you want to leave this wrap?" completion:^(NSUInteger index) {
		weakSelf.userInteractionEnabled = NO;
		[wrap leave:^(id object) {
			weakSelf.userInteractionEnabled = YES;
		} failure:^(NSError *error) {
			[error show];
			weakSelf.userInteractionEnabled = YES;
		}];
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
		WLWrapCandyCell* candyView = [streamView reusableViewOfClass:[WLWrapCandyCell class]
															 forItem:item
														 loadingType:StreamViewReusableViewLoadingTypeNib];
		candyView.item = [self.candies objectAtIndex:item.index.row];
		candyView.wrap = self.item;
		return candyView;
	} else {
		UIImageView * placeholderView = [streamView reusableViewOfClass:[UIImageView class]
																forItem:item
															loadingType:StreamViewReusableViewLoadingTypeInit];
		placeholderView.image = [UIImage imageNamed:@"img_just_candy_small"];
		placeholderView.contentMode = UIViewContentModeCenter;
		placeholderView.alpha = 0.5;
		return placeholderView;
	}
}

- (CGFloat)streamView:(StreamView*)streamView ratioForItemAtIndex:(StreamIndex)index {
	return 1;
}

- (void)streamView:(StreamView *)streamView didSelectItem:(StreamLayoutItem *)item {
	if (item.index.row < [self.candies count]) {
		WLCandy* candy = [self.candies objectAtIndex:item.index.row];
		if (candy.uploadingItem == nil) {
			[self.delegate wrapCell:self didSelectCandy:candy];
		}
	} else {
		[self.delegate wrapCellDidSelectCandyPlaceholder:self];
	}
}

@end