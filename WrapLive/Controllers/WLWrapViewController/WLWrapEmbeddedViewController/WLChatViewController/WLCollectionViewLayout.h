//
//  InversedFlowLayout.h
//  InversedFlowLayout
//
//  Created by Ravenpod on 1/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WLCollectionViewLayoutDelegate <UICollectionViewDelegate>

@optional
- (CGSize)collectionView:(UICollectionView*)collectionView sizeForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView topSpacingForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView bottomSpacingForItemAtIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView topSpacingForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath;

- (CGFloat)collectionView:(UICollectionView*)collectionView bottomSpacingForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath;

- (BOOL)collectionView:(UICollectionView*)collectionView applyContentSizeInsetForAttributes:(UICollectionViewLayoutAttributes*)attributes;

@end

@interface WLCollectionViewLayout : UICollectionViewLayout

@property (nonatomic) UICollectionViewScrollDirection scrollDirection;

@property (strong, nonatomic) NSArray* sectionFootingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* sectionHeadingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* itemFootingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* itemHeadingSupplementaryViewKinds;

- (void)registerItemHeaderSupplementaryViewKind:(NSString*)kind;

- (void)registerItemFooterSupplementaryViewKind:(NSString*)kind;

- (void)didPrepareAttributes:(UICollectionViewLayoutAttributes *)attributes withContentHeight:(CGFloat)contentHeight;

@end
