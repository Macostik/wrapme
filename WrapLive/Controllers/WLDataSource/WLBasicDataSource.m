//
//  WLBasicDataSource.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBasicDataSource.h"
#import "WLLoadingView.h"
#import "WLPaginatedSet.h"
#import "UIScrollView+Additions.h"

@interface WLBasicDataSource () <WLPaginatedSetDelegate>

@property (weak, nonatomic) WLLoadingView *loadingView;

@end

@implementation WLBasicDataSource

- (BOOL)appendable {
    if (self.appendableBlock && !self.appendableBlock(self.items)) {
        return NO;
    }
    if ([self.items isKindOfClass:[WLPaginatedSet class]]) {
        WLPaginatedSet *items = (id)self.items;
        return !items.completed;
    }
    return NO;
}

- (void)setItems:(id<WLDataSourceItems>)items {
    _items = items;
    if ([items isKindOfClass:[WLPaginatedSet class]]) {
        [WLLoadingView registerInCollectionView:self.collectionView];
        WLPaginatedSet *paginatedSet = (id)items;
        paginatedSet.delegate = self;
    }
    [self reload];
    if (self.changeBlock) self.changeBlock(items);
}

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if ([self.items isKindOfClass:[WLPaginatedSet class]]) {
        WLPaginatedSet *items = (id)self.items;
        [items newer:success failure:failure];
    } else {
        [super refresh:success failure:failure];
    }
}

- (void)append:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if ([self.items isKindOfClass:[WLPaginatedSet class]]) {
        WLPaginatedSet *items = (id)self.items;
        [items older:success failure:failure];
    }
}

- (NSUInteger)numberOfItems {
    return self.numberOfItemsBlock ? self.numberOfItemsBlock() : self.items.count;
}

- (id)itemAtIndex:(NSUInteger)index {
    return [self.items tryAt:index];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.headerIdentifier forIndexPath:indexPath];
    } else {
        if (self.appendable || !self.footerIdentifier) {
            self.loadingView = [WLLoadingView dequeueInCollectionView:self.collectionView indexPath:indexPath];
            self.loadingView.error = NO;
            [self append:nil failure:^(NSError *error) {
                [error showIgnoringNetworkError];
                if (error) self.loadingView.error = YES;
            }];
            return self.loadingView;
        } else {
            return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:self.footerIdentifier forIndexPath:indexPath];
        }
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (self.appendable) {
        UICollectionViewFlowLayout* layout = (id)collectionView.collectionViewLayout;
        if (layout.scrollDirection == UICollectionViewScrollDirectionVertical) {
            return CGSizeMake(collectionView.bounds.size.width, WLLoadingViewDefaultSize);
        } else {
            return CGSizeMake(WLLoadingViewDefaultSize, collectionView.bounds.size.height);
        }
    }
    return  self.footerSizeBlock ? self.footerSizeBlock() : self.footerSize;
}

#pragma mark - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self reload];
    if (self.changeBlock) self.changeBlock(self.items);
}

- (void)paginatedSetCompleted:(WLPaginatedSet *)group {
    if (self.headerAnimated && self.collectionView.scrollable) {
        UICollectionViewFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
        CGPoint offset = layout.scrollDirection == UICollectionViewScrollDirectionHorizontal ?
        CGPointMake(self.collectionView.contentOffset.x - WLLoadingViewDefaultSize, 0) :
        CGPointMake(0, self.collectionView.contentOffset.y - WLLoadingViewDefaultSize);
        [self.collectionView trySetContentOffset:offset animated:YES];
        self.loadingView.animating = NO;
        run_after(0.5, ^{
            [self reload];
        });
    } else {
        [self paginatedSetChanged:group];
    }
}

@end
