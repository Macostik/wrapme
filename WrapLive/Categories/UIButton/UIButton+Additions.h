//
//  UIButton+Additions.h
//  moji
//
//  Created by Ravenpod on 15.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIButton (Additions)

@property (nonatomic) BOOL active;

- (void)setActive:(BOOL)active animated:(BOOL)animated;

@end
