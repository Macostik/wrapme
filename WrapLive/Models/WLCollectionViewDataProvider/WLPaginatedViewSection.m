//
//  WLPaginatedViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPaginatedViewSection.h"
#import "WLCollectionViewDataProvider.h"

@interface WLPaginatedViewSection () <WLPaginatedSetDelegate>

@end

@implementation WLPaginatedViewSection

- (void)awakeFromNib {
    [super awakeFromNib];
    self.entries = [[WLPaginatedSet alloc] init];
    self.entries.delegate = self;
}

- (void)setEntries:(WLPaginatedSet *)entries {
    [super setEntries:entries];
    entries.delegate = self;
}

- (void)append:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (!self.entries.request.loading) {
        self.entries.request.type = WLPaginatedRequestTypeOlder;
        __weak typeof(self)weakSelf = self;
        [self.entries send:^(NSOrderedSet *orderedSet) {
            [weakSelf didChangeEntries:weakSelf.entries];
            weakSelf.completed = weakSelf.entries.completed;
            if (success) {
                success(orderedSet);
            }
        } failure:failure];
    }
}

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (!self.entries.request.loading) {
        self.entries.request.type = WLPaginatedRequestTypeNewer;
        __weak typeof(self)weakSelf = self;
        [self.entries send:^(NSOrderedSet *orderedSet) {
            if (orderedSet.nonempty) {
                [weakSelf didChangeEntries:weakSelf.entries];
            }
            if (success) {
                success(orderedSet);
            }
        } failure:failure];
    }
}

- (void)setCompleted:(BOOL)completed {
    _completed = completed;
    [self reload];
}

- (CGSize)footerSize:(NSUInteger)section {
    return self.completed ? CGSizeZero : [super footerSize:section];
}

- (id)footer:(NSIndexPath *)indexPath {
    [self append:nil failure:^(NSError *error) {
        [error showIgnoringNetworkError];
    }];
    static NSString* identifier = @"WLLoadingView";
    return [self.collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:identifier forIndexPath:indexPath];
}

#pragma mark - WLPaginatedSetDelegate

- (void)paginatedSetChanged:(WLPaginatedSet *)group {
    [self didChangeEntries:self.entries];
    [self reload];
}

@end
