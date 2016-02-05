//
//  StreamCell.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@interface StreamReusableView () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) UITapGestureRecognizer *selectTapGestureRecognizer;

@end

@implementation StreamReusableView

- (UIView *)contentView {
    if (_contentView == nil) {
        return self;
    } else {
        return _contentView;
    }
}

- (void)layoutWithMetrics:(StreamMetrics *)metrics {}

- (void)loadedWithMetrics:(StreamMetrics *)metrics {
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(select)];
    gestureRecognizer.delegate = self;
    [self addGestureRecognizer:gestureRecognizer];
    self.selectTapGestureRecognizer = gestureRecognizer;
}

- (void)setEntry:(id)entry {
    _entry = entry;
    [self setup:entry];
}

- (void)setup:(id)entry {}

- (void)resetup {
    [self setup:self.entry];
}

- (void)select:(id)entry {
    [self.metrics select:self.item entry:entry];
}

- (IBAction)select {
    [self select:self.entry];
}

- (void)didDequeue {}

- (void)willEnqueue {}

// MARK: - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return gestureRecognizer != self.selectTapGestureRecognizer || self.metrics.selectable;
}

@end
