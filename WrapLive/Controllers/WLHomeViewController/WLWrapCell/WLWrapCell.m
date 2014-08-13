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
#import "WLCollectionViewDataProvider.h"
#import "WLHomeCandiesViewSection.h"

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *candiesView;
@property (weak, nonatomic) IBOutlet UIImageView *notifyBulb;
@property (strong, nonatomic) WLMenu* menu;
@property (strong, nonatomic) WLCollectionViewDataProvider* candiesDataProvider;
@property (strong, nonatomic) WLHomeCandiesViewSection* candiesDataSection;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    self.menu = [WLMenu menuWithView:self.candiesView ? self.nameLabel.superview : self configuration:^BOOL(WLMenu *menu) {
        WLWrap* wrap = weakSelf.entry;
        if ([wrap.contributor isCurrentUser]) {
            [menu addItem:@"Delete" block:^{
                weakSelf.userInteractionEnabled = NO;
                [wrap remove:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
        } else {
            [menu addItem:@"Leave" block:^{
                weakSelf.userInteractionEnabled = NO;
                [wrap leave:^(id object) {
                    weakSelf.userInteractionEnabled = YES;
                } failure:^(NSError *error) {
                    [error show];
                    weakSelf.userInteractionEnabled = YES;
                }];
            }];
        }
        return YES;
    }];
    UICollectionViewFlowLayout* layout = (id)self.candiesView.collectionViewLayout;
    CGFloat size = self.candiesView.bounds.size.width/3.0f - 0.5f;
    layout.itemSize = CGSizeMake(size, size);
    layout.minimumLineSpacing = WLCandyCellSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
    
    if (self.candiesView) {
        WLHomeCandiesViewSection* section = [[WLHomeCandiesViewSection alloc] initWithCollectionView:self.candiesView];
        section.reuseCellIdentifier = WLCandyCellIdentifier;
        section.selection = self.selection;
        self.candiesDataSection = section;
        self.candiesDataProvider = [WLCollectionViewDataProvider dataProvider:self.candiesView section:section];
    }
}

- (void)setSelection:(WLObjectBlock)selection {
    [super setSelection:selection];
    self.candiesDataSection.selection = selection;
}

- (void)setup:(WLWrap*)wrap {
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

- (void)setCandies:(NSMutableOrderedSet *)candies {
    self.candiesDataSection.entries = candies;
}

- (IBAction)select:(id)sender {
	self.notifyBulb.hidden = YES;
	WLWrap* wrap = self.entry;
    wrap.unread = @NO;
    [super select:sender];
}

@end