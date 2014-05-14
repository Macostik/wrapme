//
//  WLWrapCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

static NSUInteger WLHomeTopWrapCandiesLimit = 6;
static NSUInteger WLHomeTopWrapCandiesLimit_2 = 3;

@class WLWrapCell;
@class WLCandy;
@class WLWrap;

@protocol WLWrapCellDelegate <NSObject>

- (void)wrapCell:(WLWrapCell*)cell didSelectCandy:(WLCandy*)candy;
- (void)wrapCellDidSelectCandyPlaceholder:(WLWrapCell*)cell;

@optional

- (void)wrapCell:(WLWrapCell *)cell didSelectWrap:(WLWrap *)wrap;

@end

@interface WLWrapCell : WLItemCell

@property (nonatomic, weak) id <WLWrapCellDelegate> delegate;

@property (strong, nonatomic) NSArray* candies;

@end
