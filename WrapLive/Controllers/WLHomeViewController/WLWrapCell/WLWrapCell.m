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

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet StreamView *streamView;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
	UILongPressGestureRecognizer* removeGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(remove:)];
	[self.nameLabel.superview addGestureRecognizer:removeGestureRecognizer];
}

- (void)setupItemData:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
	self.coverView.imageUrl = wrap.picture.small;
	self.contributorsLabel.text = wrap.contributorNames;
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
}

- (void)setCandies:(NSArray *)candies {
	_candies = candies;
	[self.streamView reloadData];
}

- (void)remove:(UILongPressGestureRecognizer*)sender {
	if (sender.state == UIGestureRecognizerStateBegan && self.userInteractionEnabled) {
		__weak typeof(self)weakSelf = self;
		WLWrap* wrap = weakSelf.item;
		if ([wrap.contributor isCurrentUser]) {
			[UIActionSheet showWithTitle:nil cancel:@"Cancel" destructive:@"Delete" buttons:nil completion:^(NSUInteger index) {
				[UIActionSheet showWithTitle:@"Are you sure you want to delete this wrap?" cancel:@"No" destructive:@"Yes" buttons:nil completion:^(NSUInteger index) {
					weakSelf.userInteractionEnabled = NO;
					[[WLAPIManager instance] removeWrap:wrap success:^(id object) {
						weakSelf.userInteractionEnabled = YES;
					} failure:^(NSError *error) {
						[error show];
						weakSelf.userInteractionEnabled = YES;
					}];
				}];
			}];
		}
	}
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