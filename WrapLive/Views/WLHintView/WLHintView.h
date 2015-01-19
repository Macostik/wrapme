//
//  WLHintView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/19/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLGradientView.h"

@interface WLHintView : WLGradientView

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName;

+ (BOOL)showHintViewFromNibNamed:(NSString*)nibName inView:(UIView*)view;

@end
