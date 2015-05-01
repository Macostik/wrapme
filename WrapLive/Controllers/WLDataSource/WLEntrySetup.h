//
//  WLEntrySetup.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/14/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WLEntrySetup <NSObject>

@property (strong, nonatomic) id entry;

@property (strong, nonatomic) WLObjectBlock selectionBlock;

+ (CGSize)sizeInCollectionView:(UICollectionView*)collectionView index:(NSUInteger)index entry:(id)entry;

+ (CGSize)sizeInCollectionView:(UICollectionView*)collectionView index:(NSUInteger)index entry:(id)entry defaultSize:(CGSize)defaultSize;

- (void)setup:(id)entry;

- (void)resetup;

- (void)select:(id)entry;

@end
