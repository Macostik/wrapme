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
    if (self.change) {
        self.change(entries);
    }
}

- (NSUInteger)numberOfEntries {
    if (self.entriesNumber) {
        return self.entriesNumber();
    } else {
        return [self.entries.entries count];
    }
}

- (id)cellWithIdentifier:(NSString *)identifier indexPath:(NSIndexPath *)indexPath {
    if (self.cell) {
        return self.cell(identifier, indexPath);
    } else {
        WLEntryCell* cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
        cell.selection = self.selection;
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
    if (self.size) {
        return self.size(indexPath);
    } else {
        UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
        return layout.itemSize;
    }
}

- (id)header:(NSIndexPath*)indexPath {
    if (self.header) {
        return self.header(self.reuseHeaderViewIdentifier, indexPath);
    } else {
        return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:self.reuseFooterViewIdentifier forIndexPath:indexPath];
    }
}

- (id)footer:(NSIndexPath*)indexPath {
    if (self.footer) {
        return self.footer(self.reuseFooterViewIdentifier, indexPath);
    } else {
        return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:self.reuseFooterViewIdentifier forIndexPath:indexPath];
    }
}

- (CGSize)headerSize:(NSUInteger)section {
    if (self.headerSize) {
        return self.headerSize(section);
    } else {
        UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
        return layout.headerReferenceSize;
    }
}

- (CGSize)footerSize:(NSUInteger)section {
    if (self.footerSize) {
        return self.footerSize(section);
    } else {
        UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
        return layout.footerReferenceSize;
    }
}

- (CGFloat)minimumLineSpacing:(NSUInteger)section {
    if (self.minimumLineSpacing) {
        return self.minimumLineSpacing(section);
    } else {
        UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
        return layout.minimumLineSpacing;
    }
}

- (UIEdgeInsets)sectionInsets:(NSUInteger)section {
    if (self.sectionInsets) {
        return self.sectionInsets(section);
    } else {
        UICollectionViewFlowLayout* layout = (id)self.collectionView.collectionViewLayout;
        return layout.sectionInset;
    }
}

@end
