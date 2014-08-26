//
//  WLTimelineEventCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineEventCell.h"
#import "WLTimelineEvent.h"
#import "WLImageView.h"
#import "NSDate+Formatting.h"
#import "WLUser.h"
#import "WLCollectionViewDataProvider.h"
#import "WLCandiesViewSection.h"
#import "WLCandyCell.h"

@interface WLTimelineEventCell ()

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (strong, nonatomic) WLCollectionViewDataProvider* dataProvider;
@property (strong, nonatomic) WLCollectionViewSection* dataSection;

@end

@implementation WLTimelineEventCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    layout.minimumLineSpacing = WLCandyCellSpacing;
    layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
    
    WLCollectionViewSection* section = [[WLCollectionViewSection alloc] initWithCollectionView:self.collectionView];
    section.reuseCellIdentifier = WLCandyCellIdentifier;
    section.selection = self.selection;
    self.dataSection = section;
    self.dataProvider = [WLCollectionViewDataProvider dataProvider:self.collectionView section:section];
}

- (void)setup:(WLTimelineEvent *)event {
    self.dateLabel.text = [event.date stringWithFormat:@"hh:mm"];
    self.avatarView.url = event.user.picture.small;
    self.textLabel.text = event.text;
    self.dataSection.entries = event.images;
}

@end
