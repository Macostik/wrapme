//
//  WLCollectionViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionViewSection.h"
#import "WLCollectionViewDataProvider.h"

@implementation WLCollectionViewSection

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView {
    self = [super init];
    if (self) {
        self.collectionView = collectionView;
        [self setup];
    }
    return self;
}

- (instancetype)init {
    return [self initWithCollectionView:nil];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    if (self.collectionView) {
        [self setDefaults:self.collectionView];
    }
}

- (void)setCollectionView:(UICollectionView *)collectionView {
    _collectionView = collectionView;
    if (collectionView) {
        [self setDefaults:collectionView];
    }
}

- (void)setDefaults:(UICollectionView*)collectionView {
    UICollectionViewFlowLayout* layout = (id)collectionView.collectionViewLayout;
    self.defaultFooterSize = layout.footerReferenceSize;
    self.defaultHeaderSize = layout.headerReferenceSize;
    self.defaultMinimumLineSpacing = layout.minimumLineSpacing;
    self.defaultMinimumInteritemSpacing = layout.minimumInteritemSpacing;
    self.defaultSectionInsets = layout.sectionInset;
    self.defaultSize = layout.itemSize;
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
    if (self.change) {
        self.change(entries);
    }
}

- (NSUInteger)numberOfEntries {
    return [self.entries.entries count];
}

- (id)cellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath {
    if (self.cell) {
        return self.cell(identifier, indexPath);
    } else {
        WLEntryCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        cell.selectionBlock = self.selectionBlock;
        id entry = self.entries.entries[indexPath.item];
        cell.entry = entry;
        if (self.configure) {
            self.configure(cell, entry);
        }
        return cell;
    }
}

- (id)cell:(NSIndexPath *)indexPath {
    return [self cellWithIdentifier:self.reuseCellIdentifier indexPath:indexPath];
}

- (CGSize)size:(NSIndexPath*)indexPath {
    return self.defaultSize;
}

- (id)header:(NSIndexPath*)indexPath {
    if (self.defaultHeader) {
        return self.defaultHeader;
    } else {
        return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:self.reuseHeaderViewIdentifier forIndexPath:indexPath];
    }
}

- (id)footer:(NSIndexPath*)indexPath {
    if (self.defaultFooter) {
        return self.defaultFooter;
    } else {
        return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:self.reuseFooterViewIdentifier forIndexPath:indexPath];
    }
}

- (CGSize)headerSize:(NSUInteger)section {
    return self.defaultHeaderSize;
}

- (CGSize)footerSize:(NSUInteger)section {
    return self.defaultFooterSize;
}

- (CGFloat)minimumLineSpacing:(NSUInteger)section {
    return self.defaultMinimumLineSpacing;
}

- (CGFloat)minimumInteritemSpacing:(NSUInteger)section {
    return self.defaultMinimumInteritemSpacing;
}

- (UIEdgeInsets)sectionInsets:(NSUInteger)section {
    return self.defaultSectionInsets;
}

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (success) success(nil);
}

- (void)select:(NSIndexPath *)indexPath {
    if (self.selection) {
        self.selection(self.entries.entries[indexPath.item]);
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
}

@end
