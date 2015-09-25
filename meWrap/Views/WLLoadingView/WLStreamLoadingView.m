//
//  WLStreamLoadingView.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStreamLoadingView.h"

@interface WLStreamLoadingView ()

@end

@implementation WLStreamLoadingView

+ (StreamMetrics*)streamLoadingMetrics {
    return [[StreamMetrics alloc] initWithIdentifier:WLStreamLoadingViewIdentifier size:WLStreamLoadingViewDefaultSize];
}

- (void)setAnimating:(BOOL)animating {
    if (animating) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }
}

- (BOOL)animating {
    return self.spinner.isAnimating;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) {
        [self.spinner startAnimating];
    } else {
        [self.spinner stopAnimating];
    }
}

@end
