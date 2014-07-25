//
//  WLWrapCandiesCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCollectionItemCell.h"

@class WLCandiesCell;
@class WLCandy;
@class WLWrap;

@protocol WLCandiesCellDelegate <NSObject>

@optional

- (void)candiesCell:(WLCandiesCell*)cell didSelectCandy:(WLCandy*)candy;

@end

@interface WLCandiesCell : WLCollectionItemCell

@property (nonatomic, weak) id <WLCandiesCellDelegate> delegate;

@property (nonatomic) BOOL refreshable;

@property (weak, nonatomic, readonly) UICollectionView *collectionView;

@end