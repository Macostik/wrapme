//
//  WLWrap.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap.h"
#import "WLCandy.h"
#import "WLSession.h"

@implementation WLWrap

+ (NSMutableArray *)dummyWraps {
	static NSMutableArray* _wraps = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSError* error = nil;
		_wraps = [[WLWrap arrayOfModelsFromDictionaries:[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WLDummyWraps" ofType:@"plist"]] error:&error] mutableCopy];
	});
	return _wraps;
}

+ (instancetype)wrap {
	WLWrap* wrap = [[WLWrap alloc] init];
	wrap.createdAt = [NSDate date];
	wrap.author = [WLSession user];
	return wrap;
}

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
