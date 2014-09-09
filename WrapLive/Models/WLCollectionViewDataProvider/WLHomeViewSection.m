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

@interface WLHomeViewSection ()

@property (strong, nonatomic) NSOperationQueue *loadingQueue;

@end

@implementation WLHomeViewSection

- (void)didChangeEntries:(WLEntriesCollection)entries {
    self.wrap = [self.entries.entries firstObject];
    [super didChangeEntries:entries];
}

- (void)setWrap:(WLWrap *)wrap {
    BOOL changed = NO;
    if (_wrap != wrap) {
        changed = YES;
        _wrap = wrap;
    }
    if (_wrap) {
        self.candies = [_wrap recentCandies:WLHomeTopWrapCandiesLimit];
        if (changed) {
            [self fetchTopWrapIfNeeded:_wrap];
        }
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
    if ([self.candies count] < WLHomeTopWrapCandiesLimit) {
        [self.loadingQueue addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
            run_in_main_queue(^{
                [wrap fetch:^(WLWrap* wrap) {
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
		height = [self.candies count] > WLHomeTopWrapCandiesLimit_2 ? 290 : 174;
	}
	return CGSizeMake(self.collectionView.width, height);
}

- (id)cell:(NSIndexPath *)indexPath {
    static NSString* topWrapCellIdentifier = @"WLTopWrapCell";
    static NSString* wrapCellIdentifier = @"WLWrapCell";
    NSString* identifier = indexPath.item == 0 ? topWrapCellIdentifier : wrapCellIdentifier;
    WLWrapCell* cell = [self cellWithIdentifier:identifier indexPath:indexPath];
    if (indexPath.item == 0) {
        cell.candies = self.candies;
    }
	return cell;
}

@end
