//
//  WLDebugButton.m
//  moji
//
//  Created by Ravenpod on 3/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQAButton.h"

@implementation WLQAButton

- (void)awakeFromNib {
    [super awakeFromNib];
    self.hidden = [WLAPIEnvironment currentEnvironment].isProduction;
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
