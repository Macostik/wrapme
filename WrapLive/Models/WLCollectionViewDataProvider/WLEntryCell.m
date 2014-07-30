//
//  WLEntryCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/30/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

@implementation WLEntryCell

+ (CGFloat)size:(NSIndexPath *)indexPath entry:(id)entry {
    return 0;
}

- (void)setEntry:(id)entry {
    _entry = entry;
    [self setup:entry];
}

- (void)setup:(id)entry {
    
}

- (IBAction)select:(id)sender {
    if ([self.delegate respondsToSelector:@selector(entryCell:didSelectEntry:)]) {
        [self.delegate entryCell:self didSelectEntry:self.entry];
    }
}

@end
