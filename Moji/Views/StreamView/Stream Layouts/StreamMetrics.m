//
//  StreamMetrics.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamMetrics.h"
#import "StreamView.h"

@implementation StreamMetrics

+ (instancetype)metrics:(StreamMetricsBlock)block {
    return [[[self alloc] init] change:block];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.reusableViews = [NSMutableSet set];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.reusableViews = [NSMutableSet set];
    }
    return self;
}

- (instancetype)change:(StreamMetricsBlock)block {
    if (block) block(self);
    return self;
}

- (BOOL)hiddenAt:(StreamIndex *)index {
    return self.hiddenBlock ? self.hiddenBlock(index, self) : self.hidden;
}

- (CGFloat)sizeAt:(StreamIndex *)index {
    return self.sizeBlock ? self.sizeBlock(index, self) : self.size;
}

- (CGRect)insetsAt:(StreamIndex *)index {
    return self.insetsBlock ? self.insetsBlock(index, self) : self.insets;
}

- (StreamReusableView*)loadView {
    
    NSMutableSet *views = _reusableViews;
    
    if (views.count > 0) {
        StreamReusableView *view = [views anyObject];
        [views removeObject:view];
        [view prepareForReuse];
        return view;
    }
    
    UINib *nib = self.nib;
    if (!nib && self.identifier) {
        nib = [UINib nibWithNibName:self.identifier bundle:nil];
    }
    if (nib) {
        NSArray *objects = [nib instantiateWithOwner:self.nibOwner options:nil];
        for (StreamReusableView *object in objects) {
            if ([object isKindOfClass:[StreamReusableView class]]) {
                object.metrics = self;
                return object;
            }
        }
    }
    return nil;
}

- (void)select:(StreamItem *)item entry:(id)entry {
    if (self.selectionBlock && entry) {
        self.selectionBlock(item, entry);
    }
}

@end
