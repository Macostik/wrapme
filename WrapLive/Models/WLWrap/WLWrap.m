//
//  WLWrap.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap.h"

@implementation WLWrap

- (void)addEntry:(WLWrapEntry *)entry {
	if (!self.entries) {
		self.entries = (id)[NSArray arrayWithObject:entry];
	} else {
		self.entries = (id)[self.entries arrayByAddingObject:entry];
	}
}

@end
