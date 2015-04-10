//
//  WLProgressBar+WLContribution.h
//  WrapLive
//
//  Created by Sergey Maximenko on 10/31/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProgressBar.h"

static CGFloat WLDefaultProgress = 0.1f;

@interface WLProgressBar (WLContribution)

- (void)setContribution:(WLContribution *)contribution;

- (void)setContribution:(WLContribution *)contribution isHideProgress:(BOOL)hide;

- (void)setContribution:(WLContribution *)contribution isHideProgress:(BOOL)hide complition:(WLBooleanBlock)completion;

- (void)setOperation:(id)operation;

@end
