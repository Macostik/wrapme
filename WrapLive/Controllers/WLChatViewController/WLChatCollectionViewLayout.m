//
//  InversedFlowLayout.m
//  InversedFlowLayout
//
//  Created by Sergey Maximenko on 1/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLChatCollectionViewLayout.h"
#import "UIScrollView+Additions.h"

static NSString *WLCollectionElementKindItem = @"item";

@interface WLChatCollectionViewLayout ()

@property (strong, nonatomic) NSMutableDictionary* layoutKeyedAttributes;

@property (strong, nonatomic) NSMutableSet* layoutAttributes;

@property (nonatomic) CGFloat contentHeight;

@property (strong, nonatomic) NSArray* sectionFootingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* sectionHeadingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* itemFootingSupplementaryViewKinds;

@property (strong, nonatomic) NSArray* itemHeadingSupplementaryViewKinds;

@property (strong, nonatomic) NSMutableSet* insertingIndexPaths;

@end

@implementation WLChatCollectionViewLayout

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
    
    id <WLChatCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    
    NSUInteger numberOfSections = [collectionView numberOfSections];
    
    __block CGFloat contentHeight = 0;
    
    NSMutableDictionary *layoutKeyedAttributes = [NSMutableDictionary dictionary];
    
    void (^prepareLayoutAttributes) (UICollectionViewLayoutAttributes*, NSString*);
    prepareLayoutAttributes = ^(UICollectionViewLayoutAttributes *attributes, NSString* kind) {
        if (attributes) {
            attributes.hidden = CGSizeEqualToSize(attributes.size, CGSizeZero);
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
            
            for (NSString *kind in self.itemHeadingSupplementaryViewKinds) {
                UICollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
                prepareLayoutAttributes(attributes, kind);
            }
            
            if ([delegate respondsToSelector:@selector(collectionView:topInteritemSpacingForItemAtIndexPath:)]) {
                contentHeight += [delegate collectionView:collectionView topInteritemSpacingForItemAtIndexPath:indexPath];
            }
            
            UICollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForItemAtIndexPath:indexPath];
            prepareLayoutAttributes(attributes, WLCollectionElementKindItem);
            
            if ([delegate respondsToSelector:@selector(collectionView:bottomInteritemSpacingForItemAtIndexPath:)]) {
                contentHeight += [delegate collectionView:collectionView bottomInteritemSpacingForItemAtIndexPath:indexPath];
            }
            
            for (NSString *kind in self.itemFootingSupplementaryViewKinds) {
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
    
    CGFloat inset = (collectionView.height - collectionView.verticalContentInsets) - contentHeight;
    if (inset > 0) {
        for (UICollectionViewLayoutAttributes *attributes in layoutAttributes) {
            CGRect frame = attributes.frame;
            frame.origin.y += inset;
            attributes.frame = frame;
        }
    }
    
    self.layoutKeyedAttributes = layoutKeyedAttributes;
    
    self.layoutAttributes = [NSMutableSet setWithArray:layoutAttributes];
}

- (void)registerItemHeaderSupplementaryViewKind:(NSString *)kind {
    if (!kind) return;
    if (!self.itemHeadingSupplementaryViewKinds) {
        self.itemHeadingSupplementaryViewKinds = @[kind];
    } else {
        self.itemHeadingSupplementaryViewKinds = [self.itemHeadingSupplementaryViewKinds arrayByAddingObject:kind];
    }
}

- (void)registerItemFooterSupplementaryViewKind:(NSString *)kind {
    if (!kind) return;
    if (!self.itemFootingSupplementaryViewKinds) {
        self.itemFootingSupplementaryViewKinds = @[kind];
    } else {
        self.itemFootingSupplementaryViewKinds = [self.itemFootingSupplementaryViewKinds arrayByAddingObject:kind];
    }
}

- (UICollectionViewLayoutAttributes*)prepareLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionView *collectionView = self.collectionView;
    id <WLChatCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    CGSize size = CGSizeZero;
    if ([delegate respondsToSelector:@selector(collectionView:sizeForItemAtIndexPath:)]) {
        size = [delegate collectionView:collectionView sizeForItemAtIndexPath:indexPath];
    } else {
        size = CGSizeMake(collectionView.bounds.size.width, 60);
    }
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = size;
    return attributes;
}

- (UICollectionViewLayoutAttributes*)prepareLayoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    UICollectionView *collectionView = self.collectionView;
    id <WLChatCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:sizeForSupplementaryViewOfKind:atIndexPath:)]) {
        size = [delegate collectionView:collectionView sizeForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
    }
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    attributes.size = size;
    return attributes;
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.width, self.contentHeight);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [[self.layoutAttributes objectsPassingTest:^BOOL(UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
        return !attributes.hidden && CGRectIntersectsRect(rect, attributes.frame);
    }] allObjects];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForElementKind:(NSString*)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = self.layoutKeyedAttributes[elementKind][indexPath];
    if (!attributes) {
        [self calculateInitialAttributes];
        attributes = self.layoutKeyedAttributes[elementKind][indexPath];
    }
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self layoutAttributesForElementKind:WLCollectionElementKindItem atIndexPath:indexPath];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return [self layoutAttributesForElementKind:elementKind atIndexPath:indexPath];
}

@end
