//
//  WLIconButton.h
//  WrapLive
//
//  Created by Yura Granchenko on 27/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLButton.h"

@interface WLIconButton : WLButton

@property (strong, nonatomic) IBInspectable NSString *name;

@property (strong, nonatomic) IBInspectable UIColor *color;

@property (assign, nonatomic) IBInspectable CGFloat size;

@end
