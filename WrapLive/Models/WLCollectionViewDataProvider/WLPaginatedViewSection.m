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
    if (!self.entries.request.loading) {
        [self.entries older:success failure:failure];
    } else if (failure) {
        failure(nil);
    }
}

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (!self.entries.request.loading) {
        [self.entries newer:success failure:failure];
    } else if (failure) {
        failure(nil);
    }
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
    return self.completed ? CGSizeZero : [super footerSize:section];
}

- (id)footer:(NSIndexPath *)indexPath {
    static NSString* identifier = @"WLLoadingView";
    WLLoadingView* loadingView = [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:identifier forIndexPath:indexPath];
//    loadingView.error = NO;
    [self append:nil failure:^(NSError *error) {
        [error showIgnoringNetworkError];
//        loadingView.error = YES;
    }];
    return loadingView;
}

#pragma mark - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self didChangeEntries:self.entries];
    [self reload];
}

@end
