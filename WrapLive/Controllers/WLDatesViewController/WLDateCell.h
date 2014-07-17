//
//  WLDateCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionItemCell.h"

@class WLGroup;
@class WLDateCell;

@protocol WLDateCellDelegate <NSObject>

- (void)dateCell:(WLDateCell*)cell didSelectGroup:(WLGroup*)group;

@end

@interface WLDateCell : WLCollectionItemCell

@property (nonatomic, weak) id <WLDateCellDelegate> delegate;

@end
