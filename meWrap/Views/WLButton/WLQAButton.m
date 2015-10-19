//
//  WLDebugButton.m
//  meWrap
//
//  Created by Ravenpod on 3/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQAButton.h"

@implementation WLQAButton

- (void)awakeFromNib {
    [super awakeFromNib];
#ifdef DEBUG
    self.hidden = NO;
#else
    self.hidden = [ENV isEqualToString:WLAPIEnvironmentProduction];
#endif
}

@end

@implementation WLDebugButton

- (void)awakeFromNib {
    [super awakeFromNib];
#ifndef DEBUG
    self.hidden = YES;
#endif
}

@end
