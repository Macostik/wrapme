//
//  WLCollectionViewDataProvider.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionViewDataProvider.h"

@implementation WLCollectionViewDataProvider

+ (instancetype)dataProvider:(UICollectionView*)collectionView {
    return [self dataProvider:collectionView sections:nil];
}

+ (instancetype)dataProvider:(UICollectionView*)collectionView sections:(NSArray*)sections {
    WLCollectionViewDataProvider* dataProvider = [[WLCollectionViewDataProvider alloc] init];
    dataProvider.sections = [NSMutableArray arrayWithArray:sections];
    dataProvider.collectionView = collectionView;
    [sections makeObjectsPerformSelector:@selector(setCollectionView:) withObject:collectionView];
    collectionView.delegate = dataProvider;
    collectionView.dataSource = dataProvider;
    return dataProvider;
}

+ (instancetype)dataProvider:(UICollectionView*)collectionView section:(WLCollectionViewSection*)section {
    return [self dataProvider:collectionView sections:@[section]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    for (WLCollectionViewSection* section in self.sections) {
        section.dataProvider = self;
    }
}

- (void)reload {
    [self.collectionView reloadData];
}

- (void)reload:(WLCollectionViewSection*)section {
    NSUInteger index = [self.sections indexOfObject:section];
    if (index != NSNotFound) {
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:index]];
    }
}

- (void)connect {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.sections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WLCollectionViewSection* _section = self.sections[section];
    return [_section numberOfEntries];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLCollectionViewSection* _section = self.sections[indexPath.section];
    WLEntryCell* cell = [_section cell:indexPath];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    WLCollectionViewSection* _section = self.sections[indexPath.section];
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [_section header:indexPath];
    } else {
        return [_section footer:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    WLCollectionViewSection* _section = self.sections[section];
    return [_section headerSize:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    WLCollectionViewSection* _section = self.sections[section];
    return [_section footerSize:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLCollectionViewSection* _section = self.sections[indexPath.section];
    return [_section size:indexPath];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    WLCollectionViewSection* _section = self.sections[section];
    return [_section minimumLineSpacing:section];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    WLCollectionViewSection* _section = self.sections[section];
    return [_section sectionInsets:section];
}

@end

@implementation WLCollectionViewSection (WLCollectionViewDataProvider)

- (void)reload {
    [self.dataProvider reload:self];
}

@end
