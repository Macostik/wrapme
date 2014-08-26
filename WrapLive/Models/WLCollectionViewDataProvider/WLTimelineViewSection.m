//
//  WLTimelineViewSection.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineViewSection.h"
#import "UIView+Shorthand.h"
#import "WLTimelineEvent.h"

@implementation WLTimelineViewSection

- (CGSize)size:(NSIndexPath *)indexPath {
    WLTimelineEvent* event = self.entries.entries[indexPath.item];
    CGFloat size = self.collectionView.width/3.0f;
    size = size * ceilf(event.images.count/3.0f);
    return CGSizeMake(self.collectionView.width, (size + 28));
}

@end
