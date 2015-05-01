//
//  InversedFlowLayout.h
//  InversedFlowLayout
//
//  Created by Sergey Maximenko on 1/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WLChatCollectionViewLayoutDelegate <UICollectionViewDelegate>

@optional
- (CGSize)collectionView:(UICollectionView*)collectionView sizeForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView topInteritemSpacingForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView bottomInteritemSpacingForItemAtIndexPath:(NSIndexPath*)indexPath;

@end

@interface WLChatCollectionViewLayout : UICollectionViewLayout

- (void)registerItemHeaderSupplementaryViewKind:(NSString*)kind;

- (void)registerItemFooterSupplementaryViewKind:(NSString*)kind;

@end
