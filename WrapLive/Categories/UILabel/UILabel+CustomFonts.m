//
//  UILabel+CustomFonts.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UILabel+CustomFonts.h"
#import "UIFont+CustomFonts.h"

@implementation UILabel (CustomFonts)

- (void)awakeFromNib {
	self.font = [self.font fontWithType:self.tag];
}

@end
