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
#import "NSArray+Additions.h"

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

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        self.candies = [self.candies map:^id(id item) {
			return [WLCandy candyWithDictionary:item];
		}];
    }
    return self;
}

- (void)addCandy:(WLCandy *)candy {
	if (!self.candies) {
		self.candies = [NSArray arrayWithObject:candy];
	} else {
		self.candies = [self.candies arrayByAddingObject:candy];
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
