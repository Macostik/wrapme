//
//  WLPrimaryLayoutConstraint.h
//  WrapLive
//
//  Created by Yura Granchenko on 01/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLPrimaryLayoutConstraint : NSObject

- (void)performSwitchConstraints;
- (void)performSwitchConstraintsAnimated:(BOOL)animated;
- (void)performSwitchConstraintsAnimated:(BOOL)animated duration:(CGFloat)duration;
- (BOOL)isDefaultPriotiry;

@end
