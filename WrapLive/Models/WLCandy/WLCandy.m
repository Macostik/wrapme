//
//  WLCandy.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy.h"

@implementation WLCandy

- (void)addComment:(WLComment *)comment {
	if (!self.comments) {
		self.comments = (id)[NSArray arrayWithObject:comment];
	} else {
		self.comments = (id)[self.comments arrayByAddingObject:comment];
	}
}

@end
