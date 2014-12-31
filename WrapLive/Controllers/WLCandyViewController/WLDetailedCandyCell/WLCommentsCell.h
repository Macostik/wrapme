//
//  WLDetailedCandyCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/11/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

static NSString* WLCommentsCellIdentifier = @"WLCommentsCell";

@interface WLCommentsCell : WLEntryCell

@property (weak, nonatomic, readonly) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (void)updateBottomInset:(CGFloat)bottomInset;

@end
