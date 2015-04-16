//
//  WLEntryReusableView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/14/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryReusableView.h"

@implementation WLEntryReusableView

@synthesize entry = _entry;
@synthesize selectionBlock = _selectionBlock;

+ (CGSize)sizeInCollectionView:(UICollectionView *)collectionView index:(NSUInteger)index entry:(id)entry defaultSize:(CGSize)defaultSize {
    return defaultSize;
}

+ (CGSize)sizeInCollectionView:(UICollectionView *)collectionView index:(NSUInteger)index entry:(id)entry {
    return [self sizeInCollectionView:collectionView index:index entry:entry defaultSize:CGSizeZero];
}

- (void)setEntry:(id)entry {
    _entry = entry;
    [self setup:entry];
}

- (void)setup:(id)entry {
    
}

- (void)resetup {
    [self setup:self.entry];
}

- (void)select:(id)entry {
    WLObjectBlock selectionBlock = self.selectionBlock;
    if (selectionBlock) selectionBlock(entry);
}

- (IBAction)select {
    [self select:self.entry];
}

@end
