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
    self.hidden = [WLAPIManager manager].environment.isProduction;
}

@end
