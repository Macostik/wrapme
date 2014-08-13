//
//  WLEntryCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

@implementation WLEntryCell

+ (CGFloat)size:(NSIndexPath *)indexPath entry:(id)entry defaultSize:(CGSize)defaultSize {
    return 0;
}

+ (CGFloat)size:(NSIndexPath *)indexPath entry:(id)entry {
    return [self size:indexPath entry:entry defaultSize:CGSizeZero];
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
    if ([self.delegate respondsToSelector:@selector(entryCell:didSelectEntry:)]) {
        [self.delegate entryCell:self didSelectEntry:self.entry];
    }
}

- (IBAction)select {
    if ([self.delegate respondsToSelector:@selector(entryCell:didSelectEntry:)]) {
        [self.delegate entryCell:self didSelectEntry:self.entry];
    }
}

@end
