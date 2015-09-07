//
//  WLProgressBar+WLContribution.h
//  meWrap
//
//  Created by Ravenpod on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProgressBar.h"

static CGFloat WLDefaultProgress = 0.1f;

@interface WLProgressBar (WLContribution)

- (void)setContribution:(WLContribution *)contribution;

- (void)setOperation:(id)operation;

@end
