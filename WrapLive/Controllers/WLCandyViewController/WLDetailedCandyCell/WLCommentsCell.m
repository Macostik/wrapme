//
//  WLDetailedCandyCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/11/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCommentsCell.h"
#import "WLEntryManager.h"
#import "WLImageView.h"
#import "WLRefresher.h"
#import "WLAPIManager.h"
#import "WLNetwork.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"
#import "WLCommentCell.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import "WLCandyHeaderView.h"
#import "NSObject+AssociatedObjects.h"
#import "NSString+Additions.h"
#import "WLEntryNotifier.h"

@interface WLCommentsCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) WLRefresher *refresher;
@property (strong, nonatomic) NSMutableOrderedSet* comments;
@property (strong, nonatomic) WLCandyHeaderView* headerView;

@end

@implementation WLCommentsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 44, 0);
    self.refresher = [WLRefresher refresher:self.collectionView target:self action:@selector(refresh:) style:WLRefresherStyleOrange];
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
}

- (void)refresh:(WLRefresher*)sender {
    WLCandy* candy = self.entry;
	if (candy.uploaded) {
        [candy fetch:^(id object) {
			[sender setRefreshing:NO animated:YES];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
			[sender setRefreshing:NO animated:YES];
        }];
	} else {
        [sender setRefreshing:NO animated:YES];
    }
}

- (void)setEntry:(id)entry {
    if (self.entry != entry) {
        self.collectionView.contentOffset = CGPointMake(0, -64);
    }
    [super setEntry:entry];
}

- (void)setup:(WLCandy*)candy {
    if (self.refresher.refreshing) {
        [self.refresher setRefreshing:NO animated:YES];
    }
	
    self.nameLabel.text = [NSString stringWithFormat:@"By %@", WLString(candy.contributor.name)];
    
	[self.collectionView reloadData];
    if (!NSNumberEqual(candy.unread, @NO)) candy.unread = @NO;
}

- (void)updateBottomInset:(CGFloat)bottomInset {
    UIEdgeInsets insets = self.collectionView.contentInset;
    insets.bottom = bottomInset;
    self.collectionView.contentInset = insets;
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier candyUpdated:(WLCandy *)candy {
    self.headerView.candy = self.entry;
}

- (void)notifier:(WLEntryNotifier *)notifier commentAdded:(WLComment *)comment {
    [self.collectionView reloadData];
}

- (void)notifier:(WLEntryNotifier *)notifier commentDeleted:(WLComment *)comment {
    [self.collectionView reloadData];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WLCandy* candy = self.entry;
    self.comments = candy.comments;
	return self.comments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLComment* comment = [self.comments tryObjectAtIndex:indexPath.item];
    WLCommentCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCommentCellIdentifier forIndexPath:indexPath];
    cell.entry = comment.valid ? comment : nil;
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLComment* comment = [self.comments tryObjectAtIndex:indexPath.item];
    if (!comment.valid) {
        return CGSizeMake(collectionView.width, WLMinimumCellHeight);
    }
    CGFloat height = [comment.text heightWithFont:[UIFont fontWithName:WLFontOpenSansLight preset:WLFontPresetSmall] width:WLCommentLabelLenth cachingKey:"commentTextHeight"];
    return CGSizeMake(collectionView.width, MAX(WLMinimumCellHeight, height + WLAuthorLabelHeight + 10));
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    WLCandyHeaderView* headerView = self.headerView;
    if (!headerView) {
        headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"WLCandyHeaderView" forIndexPath:indexPath];
    }
    headerView.candy = self.entry;
    return headerView;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(collectionView.width, collectionView.width + 30);
}

@end
