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
	NSMutableArray* comments = [NSMutableArray arrayWithArray:self.comments];
	[comments insertObject:comment atIndex:0];
	self.comments = [comments copy];
	self.updatedAt = [NSDate date];
}

@end
