//
//  WLWrapCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapCell.h"
#import "WLImageFetcher.h"
#import "UIView+Shorthand.h"
#import "UILabel+Additions.h"
#import "UIAlertView+Blocks.h"
#import "WLAPIManager.h"
#import "UIActionSheet+Blocks.h"
#import "StreamView.h"
#import "WLCandyCell.h"
#import "UIView+GestureRecognizing.h"
#import "WLEntryManager.h"
#import "WLWrapBroadcaster.h"
#import "WLMenu.h"

@interface WLWrapCell () <WLCandyCellDelegate, WLMenuDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;
@property (strong, nonatomic) WLMenu* menu;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.menu = [WLMenu menuWithView:self delegate:self];
}

- (void)setupItemData:(WLWrap*)wrap {
	self.nameLabel.superview.userInteractionEnabled = YES;
	self.nameLabel.text = wrap.name;
	[self.nameLabel sizeToFitWidthWithSuperviewRightPadding:50];
	self.notifyBulb.x = self.nameLabel.right + 6;
    NSString* url = [wrap.picture anyUrl];
    self.coverView.url = url;
    if (!url) {
        self.coverView.image = [UIImage imageNamed:@"default-small-cover"];
    }
	
	self.contributorsLabel.text = [wrap contributorNames];
	[self.contributorsLabel sizeToFitHeightWithMaximumHeightToSuperviewBottom];
	[self updateNotifyBulbWithWrap:wrap];
}

- (void)updateNotifyBulbWithWrap:(WLWrap *)wrap {
    self.notifyBulb.hidden = ![wrap.unread boolValue];
}

- (void)setCandies:(NSOrderedSet *)candies {
	_candies = candies;
	[self.streamView reloadData];
}

- (IBAction)wrapSelected:(UIButton *)sender {
	self.notifyBulb.hidden = YES;
	WLWrap* wrap = self.item;
    wrap.unread = @NO;
	if ([UIMenuController sharedMenuController].menuVisible) {
		[[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
	}
    if ([self.delegate respondsToSelector:@selector(wrapCell:didSelectWrap:)]) {
        [self.delegate wrapCell:self didSelectWrap:self.item];
    }
}

#pragma mark - WLMenuDelegate

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

- (NSString *)menu:(WLMenu *)menu titleForItem:(NSUInteger)item {
    WLWrap* wrap = self.item;
    return [wrap.contributor isCurrentUser] ? @"Delete" : @"Leave";
}

- (SEL)menu:(WLMenu *)menu actionForItem:(NSUInteger)item {
    WLWrap* wrap = self.item;
    return [wrap.contributor isCurrentUser] ? @selector(remove) : @selector(leave);
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