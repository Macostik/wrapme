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
    return CGSizeMake(self.collectionView.width, (self.collectionView.width/2.5f + 28.0f));
}

- (void)select:(NSIndexPath *)indexPath {
    
}

- (UIEdgeInsets)sectionInsets:(NSUInteger)section {
    return UIEdgeInsetsZero;
}

@end
