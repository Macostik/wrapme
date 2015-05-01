//
//  WLWrapCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryCell.h"

static NSUInteger WLHomeTopWrapCandiesLimit = 6;
static NSUInteger WLHomeTopWrapCandiesLimit_2 = 3;
static NSUInteger WLCandyCellHight = 212;

@class WLWrapCell;

@protocol WLWrapCellDelegate <NSObject>

- (void)wrapCell:(WLWrapCell *)wrapCell didDeleteWrap:(WLWrap *)wrap;
- (void)wrapCell:(WLWrapCell *)wrapCell forWrap:(WLWrap *)wrap notifyChatButtonClicked:(id)sender;

@end

@interface WLWrapCell : WLEntryCell

@property (strong, nonatomic) IBOutlet id <WLWrapCellDelegate> delegate;

@end
