//
//  WLHomeViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLHomeViewSection.h"
#import "WLWrapCell.h"
#import "WLOperationQueue.h"
#import "UIView+Shorthand.h"
#import "WLWrapRequest.h"

@interface WLHomeViewSection ()

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

- (void)fetchTopWrapIfNeeded:(WLWrap*)wrap {
    if ([wrap.candies count] < WLHomeTopWrapCandiesLimit) {
        runUnaryQueuedOperation(WLOperationFetchingDataQueue,^(WLOperation *operation) {
            [wrap fetch:WLWrapContentTypeRecent success:^(NSOrderedSet* candies) {
                [operation finish];
            } failure:^(NSError *error) {
                [operation finish];
            }];
        });
    }
}

- (CGSize)size:(NSIndexPath *)indexPath {
    CGFloat height = 50;
	if (indexPath.item == 0) {
        int size = (self.collectionView.bounds.size.width - 2.0f)/3.0f;;
		height = 75 + ([self.wrap.candies count] > WLHomeTopWrapCandiesLimit_2 ? 2*size : size);
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
