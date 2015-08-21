//
//  PICStreamLayout.m
//  RIOT
//
//  Created by Ravenpod on 09.10.13.
//  Copyright (c) 2013 Ravenpod. All rights reserved.
//

#import "StreamLayout.h"

@interface StreamLayout ()

@end

@implementation StreamLayout {
    CGFloat offset;
}

- (void)prepare {
    id <StreamLayoutDelegate> delegate = (id)self.streamView.delegate;
    if ([delegate respondsToSelector:@selector(streamView:layoutOffset:)]) {
        offset = [delegate streamView:self.streamView layoutOffset:self];
    } else {
        offset = 0;
    }
}

- (StreamItem *)layout:(StreamItem *)item {
    CGFloat size = [item.metrics sizeAt:item.index];
    CGRect insets = [item.metrics insetsAt:item.index];
    item.frame = CGRectMake(0 + insets.origin.x, offset + insets.origin.y, self.streamView.width - 2*insets.size.width, size + insets.size.height);
    offset += size;
    return item;
}

- (void)prepareForNextSection {
    
}

- (void)finalize {
    [self prepareForNextSection];
}

- (CGSize)contentSize {
    return CGSizeMake(self.streamView.frame.size.width, offset);
}

@end
