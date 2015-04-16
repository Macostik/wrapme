//
//  WLDataSource.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDataSource.h"
#import "WLOperationQueue.h"
#import "UIView+Shorthand.h"
#import "UIScrollView+Additions.h"
#import "WLEntryCell.h"
#import "WLFontPresetter.h"

@interface WLDataSource () <WLFontPresetterReceiver>

@property (strong, nonatomic) NSMapTable* animatingConstraintsDefaultValues;

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

- (void)setAnimatableConstraints:(NSArray *)animatableConstraints {
    _animatableConstraints = animatableConstraints;
    NSMapTable *animatingConstraintsDefaultValues = [NSMapTable strongToStrongObjectsMapTable];
    for (NSLayoutConstraint* constraint in animatableConstraints) {
        [animatingConstraintsDefaultValues setObject:@(constraint.constant) forKey:constraint];
    }
    self.animatingConstraintsDefaultValues = animatingConstraintsDefaultValues;
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index = [self indexFromIndexPath:indexPath];
    id item = [self itemAtIndex:index];
    NSString *cellIdentifier = self.cellIdentifier;
    if (self.cellIdentifierForItemBlock) {
        cellIdentifier = self.cellIdentifierForItemBlock(item, index);
    }
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
    if (index >= [self numberOfItems]) {
        
    }
    return  self.itemSizeBlock ? self.itemSizeBlock([self itemAtIndex:index], index) : self.itemSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumLineSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.minimumInteritemSpacing;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(self.sectionTopInset, self.sectionLeftInset, self.sectionBootomInset, self.sectionRightInset);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self select:indexPath];
}

- (void)select:(NSIndexPath *)indexPath {
    if (self.selectionBlock) {
        self.selectionBlock([self itemAtIndex:[self indexFromIndexPath:indexPath]]);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.animatableConstraints.nonempty && scrollView.tracking) {
        if (scrollView.contentSize.height > scrollView.height || self.direction == WLDataSourceScrollDirectionUp) {
            self.direction = [scrollView.panGestureRecognizer translationInView:scrollView].y > 0 ? WLDataSourceScrollDirectionDown : WLDataSourceScrollDirectionUp;
        }
    }
}

- (void)setDirection:(WLDataSourceScrollDirection)direction {
    if (_direction != direction) {
        _direction = direction;
        CGFloat constantValue = 0;
        if (direction == WLDataSourceScrollDirectionUp) {
            constantValue = -self.collectionView.height/2;
        }
        for (NSLayoutConstraint* constraint in self.animatableConstraints) {
            constraint.constant = [[self.animatingConstraintsDefaultValues objectForKey:constraint] floatValue] + constantValue;
        }
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];
        [self.collectionView.superview layoutIfNeeded];
        [UIView commitAnimations];
    }
}

#pragma mark - WLFontPresetterReceiver

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    [self reload];
}

@end
