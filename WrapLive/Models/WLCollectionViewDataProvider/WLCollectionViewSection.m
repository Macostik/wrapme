//
//  WLCollectionViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionViewSection.h"
#import "UIView+Shorthand.h"
#import "WLCollectionViewDataProvider.h"

@implementation WLCollectionViewSection

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UICollectionView *cv = self.collectionView;
    NSString* identifier = self.reuseCellIdentifier;
    BOOL registerNib = self.registerCellAfterAwakeFromNib;
    if (registerNib && identifier) {
        [cv registerNib:[UINib nibWithNibName:identifier bundle:nil] forCellWithReuseIdentifier:identifier];
    }
    identifier = self.reuseHeaderViewIdentifier;
    registerNib = self.registerHeaderAfterAwakeFromNib;
    if (registerNib && identifier) {
        [cv registerNib:[UINib nibWithNibName:identifier bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:identifier];
    }
    identifier = self.reuseFooterViewIdentifier;
    registerNib = self.registerFooterAfterAwakeFromNib;
    if (registerNib && identifier) {
        [cv registerNib:[UINib nibWithNibName:identifier bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:identifier];
    }
}

- (void)setEntries:(NSMutableOrderedSet *)entries {
    _entries = entries;
    [self reload];
}

- (NSUInteger)numberOfEntries {
    return [self.entries count];
}

- (id)cell:(NSIndexPath *)indexPath {
    WLCollectionItemCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:self.reuseCellIdentifier forIndexPath:indexPath];
    id entry = self.entries[indexPath.item];
    cell.item = entry;
    if (self.configureCellBlock) {
        self.configureCellBlock(cell, entry);
    }
    return cell;
}

- (CGSize)size:(NSIndexPath*)indexPath {
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    return layout.itemSize;
}

- (id)header:(NSIndexPath*)indexPath {
    return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:self.reuseFooterViewIdentifier forIndexPath:indexPath];
}

- (id)footer:(NSIndexPath*)indexPath {
    return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:self.reuseFooterViewIdentifier forIndexPath:indexPath];
}

- (CGSize)headerSize:(NSIndexPath*)indexPath {
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    return layout.headerReferenceSize;
}

- (CGSize)footerSize:(NSIndexPath*)indexPath {
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    return layout.footerReferenceSize;
}

- (CGFloat)minimumLineSpacing:(NSUInteger)section {
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    return layout.minimumLineSpacing;
}

- (UIEdgeInsets)sectionInsets:(NSUInteger)section {
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    return layout.sectionInset;
}

@end
