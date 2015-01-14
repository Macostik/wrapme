//
//  WLEntryCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLEntryCell;

@interface WLEntryCell : UICollectionViewCell

@property (strong, nonatomic) id entry;

@property (strong, nonatomic) WLObjectBlock selection;

+ (CGFloat)size:(NSIndexPath*)indexPath entry:(id)entry;

+ (CGFloat)size:(NSIndexPath*)indexPath entry:(id)entry defaultSize:(CGSize)defaultSize;

+ (BOOL)isEmbeddedLongPress;

- (void)setup:(id)entry;

- (void)resetup;

- (void)select:(id)entry;

@end
