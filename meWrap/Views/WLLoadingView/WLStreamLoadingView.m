//
//  WLStreamLoadingView.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStreamLoadingView.h"

@interface WLStreamLoadingView ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* spinner;

@property (weak, nonatomic) IBOutlet UIView* errorView;

@end

@implementation WLStreamLoadingView

+ (StreamMetrics*)streamLoadingMetrics {
    return [[StreamMetrics alloc] initWithIdentifier:WLStreamLoadingViewIdentifier size:WLStreamLoadingViewDefaultSize];
}

- (void)setError:(BOOL)error {
    _error = error;
    self.errorView.hidden = !error;
    self.spinner.hidden = error;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) {
        if (!self.spinner.hidden) {
            [self.spinner startAnimating];
        }
    } else {
        [self.spinner stopAnimating];
    }
}

@end
