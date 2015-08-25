//
//  StreamCell.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@implementation StreamReusableView

@synthesize entry = _entry;
@synthesize selectionBlock = _selectionBlock;

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
    WLObjectBlock selectionBlock = self.metrics.selectionBlock;
    if (selectionBlock) selectionBlock(entry);
}

- (IBAction)select {
    [self select:self.entry];
}

- (void)prepareForReuse {
    
}

@end
