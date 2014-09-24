//
//  WLHomeViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHomeViewSection.h"
#import "WLWrapCell.h"
#import "AsynchronousOperation.h"
#import "UIView+Shorthand.h"
#import "WLWrapRequest.h"

@interface WLHomeViewSection ()

@property (strong, nonatomic) NSOperationQueue *loadingQueue;

@end

@implementation WLHomeViewSection

- (void)didChangeEntries:(WLEntriesCollection)entries {
    self.wrap = [self.entries.entries firstObject];
    [super didChangeEntries:entries];
}

- (void)setWrap:(WLWrap *)wrap {
    if (_wrap != wrap) {
        _wrap = wrap;
        if (wrap) [self fetchTopWrapIfNeeded:wrap];
    }
}

- (NSOperationQueue *)loadingQueue {
    if (!_loadingQueue) {
        _loadingQueue = [[NSOperationQueue alloc] init];
        _loadingQueue.maxConcurrentOperationCount = 1;
    }
    return _loadingQueue;
}

- (void)fetchTopWrapIfNeeded:(WLWrap*)wrap {
    if ([wrap.candies count] < WLHomeTopWrapCandiesLimit) {
        [self.loadingQueue addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
            run_in_main_queue(^{
                [wrap fetch:WLWrapContentTypeRecent success:^(NSOrderedSet* candies) {
                    [operation finish];
                } failure:^(NSError *error) {
                    [operation finish];
                }];
            });
        }];
    }
}

- (CGSize)size:(NSIndexPath *)indexPath {
    CGFloat height = 50;
	if (indexPath.item == 0) {
		height = [self.wrap.candies count] > WLHomeTopWrapCandiesLimit_2 ? 277 : 171;
	}
	return CGSizeMake(self.collectionView.width, height);
}

- (id)cell:(NSIndexPath *)indexPath {
    static NSString* topWrapCellIdentifier = @"WLTopWrapCell";
    static NSString* wrapCellIdentifier = @"WLWrapCell";
    NSString* identifier = indexPath.item == 0 ? topWrapCellIdentifier : wrapCellIdentifier;
	return [self cellWithIdentifier:identifier indexPath:indexPath];
}

@end
