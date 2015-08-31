//
//  WLDataSource.m
//  moji
//
//  Created by Ravenpod on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDataSource.h"
#import "WLOperationQueue.h"
#import "UIView+Shorthand.h"
#import "UIScrollView+Additions.h"
#import "WLEntryCell.h"
#import "WLFontPresetter.h"
#import "WLLayoutPrioritizer.h"

@interface WLDataSource () <WLFontPresetterReceiver>

@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *scrollDirectionLayoutPrioritizer;

@end

@implementation WLDataSource

- (void)dealloc {
    UICollectionView* cv = self.collectionView;
    if (cv.delegate == self) cv.delegate = nil;
    if (cv.dataSource == self) cv.dataSource = nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        [self awakeAfterInit];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self awakeAfterInit];
    }
    return self;
}

- (void)awakeAfterInit {
    [[WLFontPresetter presetter] addReceiver:self];
}

- (CGSize)adjustSize:(CGSize)size {
    CGSize baseSize = self.collectionView ? self.collectionView.size : [UIScreen mainScreen].bounds.size;
    if (size.height == 0 && size.width != 0) {
        size.width = baseSize.height;
    } else if (size.width == 0 && size.height != 0) {
        size.width = baseSize.width;
    }
    return size;
}

- (void)setItemSize:(CGSize)itemSize {
    _itemSize = [self adjustSize:itemSize];
}

- (void)setHeaderSize:(CGSize)headerSize {
    _headerSize = [self adjustSize:headerSize];
}

- (void)setFooterSize:(CGSize)footerSize {
    _footerSize = [self adjustSize:footerSize];
}

+ (instancetype)dataSource:(UICollectionView*)collectionView {
    WLDataSource* dataSource = [[self alloc] init];
    dataSource.collectionView = collectionView;
    [dataSource connect];
    return dataSource;
}

- (void)reload {
    [self.collectionView reloadData];
}

- (void)connect {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

- (void)setRefreshable {
    [self setRefreshableWithStyle:WLRefresherStyleWhite];
}

- (void)setRefreshableWithStyle:(WLRefresherStyle)style contentMode:(UIViewContentMode)contentMode {
    [self setRefreshableWithStyle:style contentMode:contentMode];
}

- (void)setRefreshableWithContentMode:(UIViewContentMode)contentMode {
    [self setRefreshableWithStyle:WLRefresherStyleWhite contentMode:contentMode];
}

- (void)setRefreshableWithStyle:(WLRefresherStyle)style {
    __weak typeof(self)weakSelf = self;
    run_after_asap(^{
        [WLRefresher refresher:weakSelf.collectionView target:weakSelf action:@selector(refresh:) style:style];
    });
}

- (void)refresh {
    [self refresh:nil failure:^(NSError *error) {
        [error showIgnoringNetworkError];
    }];
}

- (void)refresh:(WLRefresher*)sender {
    [self refresh:^(id object) {
        [sender setRefreshing:NO animated:YES];
    } failure:^(NSError *error) {
        [sender setRefreshing:NO animated:YES];
    }];
}

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.refreshBlock) {
        self.refreshBlock(success, failure);
    } else if (success) {
        success(nil);
    }
}

- (NSUInteger)numberOfItems {
    return self.numberOfItemsBlock ? self.numberOfItemsBlock() : _numberOfItems;
}

- (id)itemAtIndex:(NSUInteger)index {
    return nil;
}

- (NSUInteger)indexFromIndexPath:(NSIndexPath*)indexPath {
    return indexPath.item;
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self numberOfItems];
}

- (NSString*)cellIdentifierForItem:(id)item atIndex:(NSUInteger)index {
    NSString *cellIdentifier = self.cellIdentifier;
    if (self.cellIdentifierForItemBlock) {
        cellIdentifier = self.cellIdentifierForItemBlock(item, index);
    }
    return cellIdentifier;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index = [self indexFromIndexPath:indexPath];
    id item = [self itemAtIndex:index];
    NSString *cellIdentifier = [self cellIdentifierForItem:item atIndex:index];
    WLEntryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.entry = item;
    if (self.configureCellForItemBlock) self.configureCellForItemBlock(cell, cell.entry);
    cell.selectionBlock = self.selectionBlock;
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.headerIdentifier forIndexPath:indexPath];
    } else {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.footerIdentifier forIndexPath:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return  self.headerSizeBlock ? self.headerSizeBlock() : self.headerSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return  self.footerSizeBlock ? self.footerSizeBlock() : self.footerSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index = [self indexFromIndexPath:indexPath];
    return  self.itemSizeBlock ? self.itemSizeBlock([self itemAtIndex:index], index) : self.itemSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumLineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumInteritemSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(self.sectionTopInset, self.sectionLeftInset, self.sectionBottomInset, self.sectionRightInset);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self select:indexPath];
}

- (void)select:(NSIndexPath *)indexPath {
    id item = [self itemAtIndex:[self indexFromIndexPath:indexPath]];
    if (self.selectionBlock && item) {
        self.selectionBlock(item);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.scrollDirectionLayoutPrioritizer && scrollView.tracking) {
        if (scrollView.contentSize.height > scrollView.height || self.direction == WLDataSourceScrollDirectionUp) {
            self.direction = [scrollView.panGestureRecognizer translationInView:scrollView].y > 0 ? WLDataSourceScrollDirectionDown : WLDataSourceScrollDirectionUp;
        }
    }
}

- (void)setDirection:(WLDataSourceScrollDirection)direction {
    if (_direction != direction) {
        _direction = direction;
        [self.scrollDirectionLayoutPrioritizer setDefaultState:(direction == WLDataSourceScrollDirectionDown) animated:YES];
    }
}

- (NSString *)placeholderNameOfCollectionView:(WLCollectionView *)collectioinView {
    return self.nibNamePlaceholder;
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self reload];
}

// MARK: - WLCollectionViewLayout

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
    return [self collectionView:collectionView layout:nil sizeForItemAtIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView*)collectionView sizeForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [self collectionView:collectionView layout:nil referenceSizeForHeaderInSection:indexPath.section];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
        return [self collectionView:collectionView layout:nil referenceSizeForFooterInSection:indexPath.section];
    }
    return CGSizeZero;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView topSpacingForItemAtIndexPath:(NSIndexPath*)indexPath {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView bottomSpacingForItemAtIndexPath:(NSIndexPath*)indexPath {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView topSpacingForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    return 0;
}

- (CGFloat)collectionView:(UICollectionView*)collectionView bottomSpacingForSupplementaryViewOfKind:(NSString*)kind atIndexPath:(NSIndexPath*)indexPath {
    return 0;
}

- (BOOL)collectionView:(UICollectionView*)collectionView applyContentSizeInsetForAttributes:(UICollectionViewLayoutAttributes*)attributes {
    return NO;
}

@end
