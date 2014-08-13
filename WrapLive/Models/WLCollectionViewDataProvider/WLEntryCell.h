//
//  WLEntryCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLEntryCell;

@protocol WLEntryCellDelegate <NSObject>

@optional
- (void)entryCell:(WLEntryCell*)cell didSelectEntry:(id)entry;

@end

@interface WLEntryCell : UICollectionViewCell

@property (strong, nonatomic) id entry;

@property (nonatomic, weak) id <WLEntryCellDelegate> delegate;

+ (CGFloat)size:(NSIndexPath*)indexPath entry:(id)entry;

+ (CGFloat)size:(NSIndexPath*)indexPath entry:(id)entry defaultSize:(CGSize)defaultSize;

- (void)setup:(id)entry;

@end
