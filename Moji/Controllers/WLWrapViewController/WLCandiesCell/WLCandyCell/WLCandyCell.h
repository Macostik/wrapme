//
//  WLWrapCandyCell.h
//  moji
//
//  Created by Ravenpod on 26.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

static NSString* WLCandyitemIdentifier = @"WLCandyCell";
static CGFloat WLCandyCellSpacing = 0.5f;
static CGFloat WLCandyCellSpacingNotRetina = 1.0f;

@class WLCandyCell;

@protocol WLCandyCellDelegate <NSObject>

@optional

- (void)candyCell:(WLCandyCell *)cell didSelectCandy:(WLCandy *)candy;

@end

@interface WLCandyCell : WLEntryCell

@property (nonatomic) IBInspectable BOOL disableMenu;
@property (assign, nonatomic) IBOutlet id <WLCandyCellDelegate> delegate;


@end
