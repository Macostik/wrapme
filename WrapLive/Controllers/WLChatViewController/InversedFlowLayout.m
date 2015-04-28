//
//  InversedFlowLayout.m
//  InversedFlowLayout
//
//  Created by Sergey Maximenko on 1/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "InversedFlowLayout.h"
#import "UIScrollView+Additions.h"

@interface InversedFlowLayout ()

@property (strong, nonatomic) NSMutableDictionary* layoutKeyedAttributes;

@property (strong, nonatomic) NSMutableSet* layoutAttributes;

@property (nonatomic) CGFloat contentHeight;

@property (strong, nonatomic) NSArray* sectionFootingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* sectionHeadingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* cellFootingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* cellHeadingSupplementaryViewKinds;

@end

@implementation InversedFlowLayout

- (void)prepareLayout {
    
    if (!self.sectionFootingSupplementaryViewKinds) {
        self.sectionFootingSupplementaryViewKinds = @[UICollectionElementKindSectionFooter];
    }
    
    if (!self.sectionHeadingSupplementaryViewKinds) {
        self.sectionHeadingSupplementaryViewKinds = @[UICollectionElementKindSectionHeader];
    }
    
    [self calculateInitialAttributes];
    
    [super prepareLayout];
}

- (void)calculateInitialAttributes {
    NSMutableArray *layoutAttributes = [NSMutableArray array];
    
    UICollectionView *collectionView = self.collectionView;
    
    id <InversedFlowLayoutDelegate> delegate = (id)collectionView.delegate;
    
    NSUInteger numberOfSections = [collectionView numberOfSections];
    
    __block CGFloat contentHeight = 0;
    
    NSMutableDictionary *layoutKeyedAttributes = [NSMutableDictionary dictionary];
    
    void (^prepareLayoutAttributes) (UICollectionViewLayoutAttributes*, NSString*);
    prepareLayoutAttributes = ^(UICollectionViewLayoutAttributes *attributes, NSString* kind) {
        if (attributes) {
            CGSize size = attributes.size;
            attributes.frame = CGRectMake(0, contentHeight, size.width, size.height);
            contentHeight += attributes.size.height;
            [layoutAttributes addObject:attributes];
            NSMutableDictionary *layoutKeyedAttributesForKind = [layoutKeyedAttributes objectForKey:kind];
            if (!layoutKeyedAttributesForKind) {
                layoutKeyedAttributesForKind = layoutKeyedAttributes[kind] = [NSMutableDictionary dictionary];
            }
            [layoutKeyedAttributesForKind setObject:attributes forKey:attributes.indexPath];
        }
    };
    
    for (NSUInteger section = 0; section < numberOfSections; ++section) {
        
        for (NSString *kind in self.sectionHeadingSupplementaryViewKinds) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
            prepareLayoutAttributes(attributes, kind);
        }
        
        NSUInteger numberOfItems = [collectionView numberOfItemsInSection:section];
        for (NSUInteger item = 0; item < numberOfItems; ++item) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            for (NSString *kind in self.cellHeadingSupplementaryViewKinds) {
                UICollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
                prepareLayoutAttributes(attributes, kind);
            }
            
            if ([delegate respondsToSelector:@selector(collectionView:topInteritemSpacingForItemAtIndexPath:)]) {
                contentHeight += [delegate collectionView:collectionView topInteritemSpacingForItemAtIndexPath:indexPath];
            }
            
            UICollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForItemAtIndexPath:indexPath];
            prepareLayoutAttributes(attributes, @"cell");
            
            if ([delegate respondsToSelector:@selector(collectionView:bottomInteritemSpacingForItemAtIndexPath:)]) {
                contentHeight += [delegate collectionView:collectionView bottomInteritemSpacingForItemAtIndexPath:indexPath];
            }
            
            for (NSString *kind in self.cellFootingSupplementaryViewKinds) {
                UICollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
                prepareLayoutAttributes(attributes, kind);
            }
        }
        
        for (NSString *kind in self.sectionFootingSupplementaryViewKinds) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            UICollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
            prepareLayoutAttributes(attributes, kind);
        }
    }
    
    self.contentHeight = contentHeight;
    
    self.layoutKeyedAttributes = layoutKeyedAttributes;
    
    self.layoutAttributes = [NSMutableSet setWithArray:layoutAttributes];
}

- (void)registerItemHeaderSupplementaryViewKind:(NSString *)kind {
    if (!kind) return;
    if (!self.cellHeadingSupplementaryViewKinds) {
        self.cellHeadingSupplementaryViewKinds = @[kind];
    } else {
        self.cellHeadingSupplementaryViewKinds = [self.cellHeadingSupplementaryViewKinds arrayByAddingObject:kind];
    }
}

- (void)registerItemFooterSupplementaryViewKind:(NSString *)kind {
    if (!kind) return;
    if (!self.cellFootingSupplementaryViewKinds) {
        self.cellFootingSupplementaryViewKinds = @[kind];
    } else {
        self.cellFootingSupplementaryViewKinds = [self.cellFootingSupplementaryViewKinds arrayByAddingObject:kind];
    }
}

- (UICollectionViewLayoutAttributes*)prepareLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionView *collectionView = self.collectionView;
    id <InversedFlowLayoutDelegate> delegate = (id)collectionView.delegate;
    CGSize size = CGSizeZero;
    if ([delegate respondsToSelector:@selector(collectionView:sizeForItemAtIndexPath:)]) {
        size = [delegate collectionView:collectionView sizeForItemAtIndexPath:indexPath];
    } else {
        size = CGSizeMake(collectionView.bounds.size.width, 60);
    }
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = size;
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        attributes.hidden = YES;
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes*)prepareLayoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    UICollectionView *collectionView = self.collectionView;
    id <InversedFlowLayoutDelegate> delegate = (id)collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:sizeForSupplementaryViewOfKind:atIndexPath:)]) {
        size = [delegate collectionView:collectionView sizeForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
    }
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    attributes.size = size;
    if (CGSizeEqualToSize(size, CGSizeZero)) {
        attributes.hidden = YES;
    }
    return attributes;
}

- (void)invalidate {
//    [self invalidateLayoutWithContext:self.invalidationContext];
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.bounds.size.width, self.contentHeight);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [[self.layoutAttributes objectsPassingTest:^BOOL(UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
        return !attributes.hidden && CGRectIntersectsRect(rect, attributes.frame);
    }] allObjects];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = self.layoutKeyedAttributes[@"cell"][indexPath];
    if (!attributes) {
        [self calculateInitialAttributes];
        attributes = self.layoutKeyedAttributes[@"cell"][indexPath];
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = self.layoutKeyedAttributes[elementKind][indexPath];
    if (!attributes) {
        [self calculateInitialAttributes];
        attributes = self.layoutKeyedAttributes[elementKind][indexPath];
    }
    return attributes;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    
    NSMutableSet* animatingIndexPaths = [NSMutableSet set];
    for (UICollectionViewUpdateItem *item in updateItems) {
        /*if (item.updateAction == UICollectionUpdateActionInsert)*/ {
            [animatingIndexPaths addObject:item.indexPathAfterUpdate];
        }
    }
    self.animatingIndexPaths = animatingIndexPaths;
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    self.animatingIndexPaths = nil;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    UICollectionViewLayoutAttributes *attributes = [[super layoutAttributesForItemAtIndexPath:itemIndexPath] copy];
    attributes.transform = CGAffineTransformMakeScale(0.5, 0.5);
    return attributes;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath {
    UICollectionViewLayoutAttributes *attributes = [[super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:elementIndexPath] copy];
    attributes.transform = CGAffineTransformMakeScale(0.5, 0.5);
    return attributes;
}

@end
