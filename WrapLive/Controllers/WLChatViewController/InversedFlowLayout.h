//
//  InversedFlowLayout.h
//  InversedFlowLayout
//
//  Created by Sergey Maximenko on 1/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InversedFlowLayoutDelegate <UICollectionViewDelegate>

@optional
- (CGSize)collectionView:(UICollectionView*)collectionView sizeForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath;

@end

@interface InversedFlowLayout : UICollectionViewLayout

@property (strong, nonatomic) NSMutableSet* animatingIndexPaths;

- (void)invalidate;

- (void)registerItemHeaderSupplementaryViewKind:(NSString*)kind;

@end
