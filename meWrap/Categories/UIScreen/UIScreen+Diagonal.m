//
//  UIScreen+Diagonal.m
//  meWrap
//
//  Created by Ravenpod on 07.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UIScreen+Diagonal.h"

@implementation UIScreen (Diagonal)

- (ScreenDiagonal)diagonal {
	static ScreenDiagonal diagonal;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (self.bounds.size.height > 480) {
			diagonal = ScreenDiagonal4;
		} else {
			diagonal = ScreenDiagonal3_5;
		}
	});
	return diagonal;
}

@end
