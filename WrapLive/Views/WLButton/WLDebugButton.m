//
//  WLDebugButton.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDebugButton.h"

@implementation WLDebugButton

- (void)awakeFromNib {
    [super awakeFromNib];
#ifndef DEBUG
    self.hidden = YES;
#else
    self.hidden = NO;
#endif
}

@end
