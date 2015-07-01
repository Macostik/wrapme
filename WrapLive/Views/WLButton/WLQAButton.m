//
//  WLDebugButton.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQAButton.h"

@implementation WLQAButton

- (void)awakeFromNib {
    [super awakeFromNib];
    self.hidden = [WLAPIManager manager].environment.isProduction;
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
