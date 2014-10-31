//
//  WLProgressBar+WLContribution.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProgressBar.h"

static CGFloat WLDefaultProgress = 0.1f;

@class WLContribution;

@interface WLProgressBar (WLContribution)

- (void)setContribution:(WLContribution *)contribution;

- (void)setOperation:(id)operation;

@end
