//
//  WLWrapCandiesCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryCell.h"

@interface WLCandiesCell : WLEntryCell

@property (nonatomic) BOOL refreshable;

@property (weak, nonatomic, readonly) UICollectionView *collectionView;

@end