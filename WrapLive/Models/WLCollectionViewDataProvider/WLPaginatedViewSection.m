//
//  WLPaginatedViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedViewSection.h"
#import "WLCollectionViewDataProvider.h"
#import "WLRefresher.h"
#import "WLLoadingView.h"

@interface WLPaginatedViewSection () <WLPaginatedSetDelegate>

@end

@implementation WLPaginatedViewSection

@dynamic entries;

- (void)awakeFromNib {
    [super awakeFromNib];
    self.entries = [[WLPaginatedSet alloc] init];
    self.entries.delegate = self;
}

- (void)setCompleted:(BOOL)completed {
    self.entries.completed = completed;
    [self reload];
}

- (BOOL)completed {
    return self.entries.completed;
}

- (void)setEntries:(WLPaginatedSet *)entries {
    [super setEntries:entries];
    entries.delegate = self;
}

- (void)append:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    [self.entries older:success failure:failure];
}

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    [self.entries newer:success failure:failure];
}

- (void)append {
    [self append:nil failure:^(NSError *error) {
        [error showIgnoringNetworkError];
    }];
}

- (void)refresh {
    [self refresh:nil failure:^(NSError *error) {
        [error showIgnoringNetworkError];
    }];
}

- (CGSize)footerSize:(NSUInteger)section {
    if (self.completed) return CGSizeZero;
    UICollectionView *collectionView = self.collectionView;
    UICollectionViewFlowLayout* layout = (id)collectionView.collectionViewLayout;
    if (layout.scrollDirection == UICollectionViewScrollDirectionVertical) {
        return CGSizeMake(collectionView.bounds.size.width, WLLoadingViewDefaultSize);
    } else {
        return CGSizeMake(WLLoadingViewDefaultSize, collectionView.bounds.size.height);
    }
}

- (id)footer:(NSIndexPath *)indexPath {
    WLLoadingView* loadingView = [WLLoadingView dequeueInCollectionView:self.collectionView indexPath:indexPath];
    loadingView.error = NO;
    [self append:nil failure:^(NSError *error) {
        [error showIgnoringNetworkError];
        if (error) loadingView.error = YES;
    }];
    return loadingView;
}

#pragma mark - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self didChangeEntries:self.entries];
    [self reload];
}

@end
