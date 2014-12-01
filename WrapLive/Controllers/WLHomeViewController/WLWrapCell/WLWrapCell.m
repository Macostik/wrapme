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
#import "UIView+Shorthand.h"
#import "WLAPIManager.h"
#import "WLCandyCell.h"
#import "WLCollectionViewDataProvider.h"
#import "WLEntryManager.h"
#import "WLEntryNotifier.h"
#import "WLHomeCandiesViewSection.h"
#import "WLImageFetcher.h"
#import "WLNotification.h"
#import "WLNotificationCenter.h"
#import "WLSizeToFitLabel.h"
#import "WLWrapCell.h"
#import "TTTAttributedLabel.h"

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *candiesView;
@property (weak, nonatomic) IBOutlet WLSizeToFitLabel *wrapNotificationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *chatNotificationImageView;
@property (strong, nonatomic) WLCollectionViewDataProvider* candiesDataProvider;
@property (strong, nonatomic) WLHomeCandiesViewSection* candiesDataSection;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
    
    if (self.candiesView) {
        UICollectionViewFlowLayout* layout = (id)self.candiesView.collectionViewLayout;
        layout.minimumLineSpacing = WLCandyCellSpacing;
        layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
        
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
    if (self.coverView) {
        NSString* url = [wrap.picture anyUrl];
        self.coverView.url = url;
        if (!url) self.coverView.image = [UIImage imageNamed:@"default-small-cover"];
    }
    self.dateLabel.text = [NSString stringWithFormat:@"last updated %@", WLString(wrap.updatedAt.timeAgoString)];
    
    if (self.candiesView) {
        self.candiesDataSection.entries = [wrap recentCandies:WLHomeTopWrapCandiesLimit];
    } else {
        self.wrapNotificationLabel.intValue = [wrap unreadNotificationsCandyCount];
    }
    self.chatNotificationImageView.hidden = [wrap unreadNotificationsMessageCount] == 0;
}

- (void)select:(WLWrap*)wrap {
    [wrap.candies all:^(WLCandy *candy) {
        if (!NSNumberEqual(candy.unread, @NO)) candy.unread = @NO;
    }];
    [super select:wrap];
}

@end