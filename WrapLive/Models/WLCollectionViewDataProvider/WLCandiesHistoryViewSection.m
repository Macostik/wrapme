//
//  WLCandiesHistoryViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/13/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCandiesHistoryViewSection.h"
#import "UIView+Shorthand.h"
#import "WLWrapRequest.h"
#import "WLGroupedSet.h"

@implementation WLCandiesHistoryViewSection

- (CGSize)size:(NSIndexPath *)indexPath {
    return CGSizeMake(self.collectionView.width, (self.collectionView.width/2.5 + 28));
}

- (void)append:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLWrapRequest* request = (id)self.entries.request;
    request.page = ((self.entries.entries.count + 1)/10 + 1);
    [super append:success failure:failure];
}

- (void)select:(NSIndexPath *)indexPath {
    
}

@end
