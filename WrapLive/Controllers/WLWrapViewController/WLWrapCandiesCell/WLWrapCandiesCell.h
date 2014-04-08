//
//  WLWrapCandiesCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 26.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLWrapCandiesCell;
@class WLCandy;
@class WLWrap;

@protocol WLWrapCandiesCellDelegate <NSObject>

@optional

- (void)wrapCandiesCell:(WLWrapCandiesCell*)cell didSelectCandy:(WLCandy*)candy;

@end

@interface WLWrapCandiesCell : WLItemCell

@property (strong, nonatomic) WLWrap *wrap;

@property (nonatomic, weak) id <WLWrapCandiesCellDelegate> delegate;

@end