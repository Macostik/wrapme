//
//  InversedFlowLayout.m
//  InversedFlowLayout
//
//  Created by Sergey Maximenko on 1/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLCollectionViewLayout.h"
#import "UIScrollView+Additions.h"

static NSString *WLCollectionElementKindItem = @"item";

@interface WLChatCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes

@property (nonatomic) CGFloat topSpacing;

@property (nonatomic) CGFloat bottomSpacing;

@end

@implementation WLChatCollectionViewLayoutAttributes

- (id)copyWithZone:(NSZone *)zone {
    WLChatCollectionViewLayoutAttributes *copy = [super copyWithZone:zone];
    copy.topSpacing = self.topSpacing;
    copy.bottomSpacing = self.bottomSpacing;
    return copy;
}

@end

@interface WLCollectionViewLayout ()

@end

@implementation WLCollectionViewLayout {
    CGFloat contentHeight;
    CGFloat contentOffset;
    NSMutableDictionary* layoutKeyedAttributes;
    NSMutableArray* layoutAttributesArray;
}

+ (Class)layoutAttributesClass {
    return [WLChatCollectionViewLayoutAttributes class];
}

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
    
    if (layoutAttributesArray) {
        [layoutAttributesArray removeAllObjects];
    } else {
        layoutAttributesArray = [NSMutableArray array];
    }
    
    if (layoutKeyedAttributes) {
        [layoutKeyedAttributes removeAllObjects];
    } else {
        layoutKeyedAttributes = [NSMutableDictionary dictionary];
    }
    
    contentHeight = 0;
    contentOffset = 0;
    
    UICollectionView *collectionView = self.collectionView;
    
    id <WLCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    
    NSUInteger numberOfSections = [collectionView numberOfSections];
    
    for (NSUInteger section = 0; section < numberOfSections; ++section) {
        
        for (NSString *kind in self.sectionHeadingSupplementaryViewKinds) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            [self prepareSupplementaryViewOfKind:kind atIndexPath:indexPath];
        }
        
        NSUInteger numberOfItems = [collectionView numberOfItemsInSection:section];
        for (NSUInteger item = 0; item < numberOfItems; ++item) {
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
            
            for (NSString *kind in self.itemHeadingSupplementaryViewKinds) {
                [self prepareSupplementaryViewOfKind:kind atIndexPath:indexPath];
            }
            
            [self prepareItemIndexPath:indexPath];
            
            for (NSString *kind in self.itemFootingSupplementaryViewKinds) {
                [self prepareSupplementaryViewOfKind:kind atIndexPath:indexPath];
            }
        }
        
        for (NSString *kind in self.sectionFootingSupplementaryViewKinds) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
            [self prepareSupplementaryViewOfKind:kind atIndexPath:indexPath];
        }
    }
    
    CGFloat inset = MAX(0, (collectionView.height - collectionView.verticalContentInsets) - contentHeight);
    for (WLChatCollectionViewLayoutAttributes *attributes in layoutAttributesArray) {
        if (!attributes.hidden) {
            contentOffset += attributes.topSpacing;
            CGSize size = attributes.size;
            BOOL applyContentSizeInset = YES;
            if ([delegate respondsToSelector:@selector(collectionView:applyContentSizeInsetForAttributes:)]) {
                applyContentSizeInset = [delegate collectionView:collectionView applyContentSizeInsetForAttributes:attributes];
            }
            if (applyContentSizeInset) {
                attributes.frame = CGRectMake(0, contentOffset + inset, size.width, size.height);
            } else {
                attributes.frame = CGRectMake(0, contentOffset, size.width, size.height);
            }
            [self handleContentOffset:contentOffset withContentHeight:contentHeight forAttributes:attributes];
            contentOffset += size.height;
            contentOffset += attributes.bottomSpacing;
        }
    }
    contentHeight = contentOffset + (contentOffset != 0 ? inset : 0);
}

- (void)handleContentOffset:(CGFloat)offset withContentHeight:(CGFloat)contentHeight forAttributes:(UICollectionViewLayoutAttributes *)attributes {
    
}

- (void)prepareAttributes:(WLChatCollectionViewLayoutAttributes*)attributes ofKind:(NSString*)kind {
    if (attributes) {
        if (!attributes.hidden) {
            contentHeight += attributes.size.height;
        }
        [layoutAttributesArray addObject:attributes];
        NSMutableDictionary *layoutKeyedAttributesForKind = [layoutKeyedAttributes objectForKey:kind];
        if (!layoutKeyedAttributesForKind) {
            layoutKeyedAttributesForKind = layoutKeyedAttributes[kind] = [NSMutableDictionary dictionary];
        }
        [layoutKeyedAttributesForKind setObject:attributes forKey:attributes.indexPath];
    }
}

- (void)prepareSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    
    UICollectionView *collectionView = self.collectionView;
    
    id <WLCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    
    WLChatCollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
    
    attributes.hidden = CGSizeEqualToSize(attributes.size, CGSizeZero);
    
    if (!attributes.hidden && [delegate respondsToSelector:@selector(collectionView:topSpacingForSupplementaryViewOfKind:atIndexPath:)]) {
        attributes.topSpacing = [delegate collectionView:collectionView topSpacingForSupplementaryViewOfKind:kind atIndexPath:indexPath];
        contentHeight += attributes.topSpacing;
    }
    
    [self prepareAttributes:attributes ofKind:kind];
    
    if (!attributes.hidden && [delegate respondsToSelector:@selector(collectionView:bottomSpacingForSupplementaryViewOfKind:atIndexPath:)]) {
        attributes.bottomSpacing = [delegate collectionView:collectionView bottomSpacingForSupplementaryViewOfKind:kind atIndexPath:indexPath];
        contentHeight += attributes.bottomSpacing;
    }
}

- (void)prepareItemIndexPath:(NSIndexPath*)indexPath {
    
    UICollectionView *collectionView = self.collectionView;
    
    id <WLCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    
    WLChatCollectionViewLayoutAttributes *attributes = [self prepareLayoutAttributesForItemAtIndexPath:indexPath];
    
    attributes.hidden = CGSizeEqualToSize(attributes.size, CGSizeZero);
    
    if (!attributes.hidden && [delegate respondsToSelector:@selector(collectionView:topSpacingForItemAtIndexPath:)]) {
        attributes.topSpacing = [delegate collectionView:collectionView topSpacingForItemAtIndexPath:indexPath];
        contentHeight += attributes.topSpacing;
    }
    
    [self prepareAttributes:attributes ofKind:WLCollectionElementKindItem];
    
    if (!attributes.hidden && [delegate respondsToSelector:@selector(collectionView:bottomSpacingForItemAtIndexPath:)]) {
        attributes.bottomSpacing = [delegate collectionView:collectionView bottomSpacingForItemAtIndexPath:indexPath];
        contentHeight += attributes.bottomSpacing;
    }
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

- (WLChatCollectionViewLayoutAttributes*)prepareLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionView *collectionView = self.collectionView;
    id <WLCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    CGSize size = CGSizeZero;
    if ([delegate respondsToSelector:@selector(collectionView:sizeForItemAtIndexPath:)]) {
        size = [delegate collectionView:collectionView sizeForItemAtIndexPath:indexPath];
    } else {
        size = CGSizeMake(collectionView.bounds.size.width, 60);
    }
    WLChatCollectionViewLayoutAttributes *attributes = [WLChatCollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    attributes.size = size;
    return attributes;
}

- (WLChatCollectionViewLayoutAttributes*)prepareLayoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeZero;
    UICollectionView *collectionView = self.collectionView;
    id <WLCollectionViewLayoutDelegate> delegate = (id)collectionView.delegate;
    if ([delegate respondsToSelector:@selector(collectionView:sizeForSupplementaryViewOfKind:atIndexPath:)]) {
        size = [delegate collectionView:collectionView sizeForSupplementaryViewOfKind:elementKind atIndexPath:indexPath];
    }
    WLChatCollectionViewLayoutAttributes *attributes = [WLChatCollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:elementKind withIndexPath:indexPath];
    attributes.size = size;
    return attributes;
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.width, contentHeight);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *_attr = [NSMutableArray array];
    BOOL added = NO;
    for (UICollectionViewLayoutAttributes *attributes in layoutAttributesArray) {
        if (!attributes.hidden) {
            if (CGRectIntersectsRect(rect, attributes.frame)) {
                added = YES;
                [_attr addObject:attributes];
            } else if (added) {
                break;
            }
        }
    }
    return [_attr copy];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForElementKind:(NSString*)elementKind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attributes = layoutKeyedAttributes[elementKind][indexPath];
    if (!attributes) {
        [self calculateInitialAttributes];
        attributes = layoutKeyedAttributes[elementKind][indexPath];
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
