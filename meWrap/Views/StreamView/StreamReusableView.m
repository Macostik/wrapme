//
//  StreamCell.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@implementation StreamReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(select)];
    [self addGestureRecognizer:gestureRecognizer];
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

- (void)prepareForReuse {
    
}

- (void)setFrame:(CGRect)frame {
    if (self.item) {
        [super setFrame:self.item.frame];
    } else {
        [super setFrame:frame];
    }
}

@end
