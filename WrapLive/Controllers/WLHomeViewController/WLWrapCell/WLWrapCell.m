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
#import "WLCandyCell.h"
#import "UIView+GestureRecognizing.h"
#import "WLEntryManager.h"
#import "WLWrapBroadcaster.h"
#import "WLMenu.h"
#import "NSObject+NibAdditions.h"

@interface WLWrapCell () <WLCandyCellDelegate, WLMenuDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *candiesView;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;
@property (strong, nonatomic) WLMenu* menu;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
    self.menu = [WLMenu menuWithView:self delegate:self];
    [self.candiesView registerNib:[WLCandyCell nib] forCellWithReuseIdentifier:WLCandyCellIdentifier];
    UICollectionViewFlowLayout* layout = (id)self.candiesView.collectionViewLayout;
    CGFloat size = self.candiesView.bounds.size.width/3.0f - 0.5f;
    layout.itemSize = CGSizeMake(size, size);
    layout.minimumLineSpacing = WLCandyCellSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
}

- (void)setupItemData:(WLWrap*)wrap {
    [WLMenu hide];
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
	[self.candiesView reloadData];
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

#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return ([self.candies count] > WLHomeTopWrapCandiesLimit_2) ? WLHomeTopWrapCandiesLimit : WLHomeTopWrapCandiesLimit_2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.item < [self.candies count]) {
		WLCandyCell* candyView = [collectionView dequeueReusableCellWithReuseIdentifier:WLCandyCellIdentifier forIndexPath:indexPath];
		candyView.item = [self.candies objectAtIndex:indexPath.item];
		candyView.delegate = self;
		return candyView;
	} else {
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"CandyPlaceholderCell" forIndexPath:indexPath];
	}
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item >= [self.candies count]) {
		[self.delegate wrapCellDidSelectCandyPlaceholder:self];
	}
}

#pragma mark - WLWrapCandyCellDelegate

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy {
	[self.delegate wrapCell:self didSelectCandy:candy];
}

@end