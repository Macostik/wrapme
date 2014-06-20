//
//  WLWrapCandyCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCollectionItemCell.h"

@class WLWrap;
@class WLCandy;
@class WLCandyCell;

@protocol WLCandyCellDelegate <NSObject>

- (void)candyCell:(WLCandyCell*)cell didSelectCandy:(WLCandy*)candy;

@end

@interface WLCandyCell : WLCollectionItemCell

@property (weak, nonatomic) IBOutlet id <WLCandyCellDelegate> delegate;

@end
