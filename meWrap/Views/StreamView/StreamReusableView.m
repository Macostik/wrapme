//
//  StreamCell.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@interface StreamReusableView () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation StreamReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(select)];
    gestureRecognizer.delegate = self;
    [self addGestureRecognizer:gestureRecognizer];
    self.tapGestureRecognizer = gestureRecognizer;
}

- (void)setEntry:(id)entry {
    _entry = entry;
    [self setup:entry];
}

- (void)setup:(id)entry {
    
}

- (void)resetup {
    [self setup:self.entry];
}

- (void)select:(id)entry {
    [self.metrics select:self.item entry:entry];
}

- (IBAction)select {
    [self select:self.entry];
}

- (void)didDequeue {
    
}

- (void)willEnqueue {
    
}

// MARK: - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return gestureRecognizer != self.tapGestureRecognizer || self.metrics.selectable;
}

@end
