//
//  WLWrap.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap.h"
#import "WLCandy.h"

@implementation WLWrap

- (void)addEntry:(WLCandy *)entry {
	if (!self.candies) {
		self.candies = (id)[NSArray arrayWithObject:entry];
	} else {
		self.candies = (id)[self.candies arrayByAddingObject:entry];
	}
}

- (NSString *)cover {
	if (_cover == nil) {
		WLCandy* candy = [self.candies lastObject];
		return candy.cover;
	}
	return _cover;
}

@end
