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

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    if (self.registerCellAfterAwakeFromNib) {
        [self registerCell];
    }
    if (self.registerHeaderAfterAwakeFromNib) {
        [self registerHeader];
    }
    if (self.registerFooterAfterAwakeFromNib) {
        [self registerFooter];
    }
}

- (void)registerCell {
    UICollectionView *cv = self.collectionView;
    NSString* identifier = self.reuseCellIdentifier;
    if (identifier) {
        [cv registerNib:[UINib nibWithNibName:identifier bundle:nil] forCellWithReuseIdentifier:identifier];
    }
}

- (void)registerHeader {
    UICollectionView *cv = self.collectionView;
    NSString* identifier = self.reuseHeaderViewIdentifier;
    if (identifier) {
        [cv registerNib:[UINib nibWithNibName:identifier bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:identifier];
    }
}

- (void)registerFooter {
    UICollectionView *cv = self.collectionView;
    NSString* identifier = self.reuseFooterViewIdentifier;
    if (identifier) {
        [cv registerNib:[UINib nibWithNibName:identifier bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:identifier];
    }
}

- (void)setEntries:(WLEntriesCollection)entries {
    [self willChangeEntries:_entries];
    _entries = entries;
    [self didChangeEntries:entries];
    [self reload];
}

- (void)willChangeEntries:(WLEntriesCollection)entries {
    
}

- (void)didChangeEntries:(WLEntriesCollection)entries {
    if (self.changeBlock) {
        self.changeBlock(entries);
    }
}

- (NSUInteger)numberOfEntries {
    return [self.entries.entries count];
}

- (id)cellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath {
    WLEntryCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    cell.delegate = self;
    id entry = self.entries.entries[indexPath.item];
    cell.entry = entry;
    if (self.configureCellBlock) {
        self.configureCellBlock(cell, entry);
    }
    return cell;
}

- (id)cell:(NSIndexPath *)indexPath {
    return [self cellWithIdentifier:self.reuseCellIdentifier indexPath:indexPath];
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

- (CGSize)headerSize:(NSUInteger)section {
    UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
    return layout.headerReferenceSize;
}

- (CGSize)footerSize:(NSUInteger)section {
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

#pragma mark - WLEntryCellDelegate

- (void)entryCell:(WLEntryCell *)cell didSelectEntry:(id)entry {
    if (self.selectionBlock) {
        self.selectionBlock(entry);
    }
}

@end
