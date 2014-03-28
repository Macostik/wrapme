//
//  WLCandy.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy.h"
#import "WLImage.h"
#import "WLConversation.h"

@implementation WLCandy

+ (id)candyWithDictionary:(NSDictionary *)dictionary {
	if (![dictionary isKindOfClass:[NSDictionary class]]) {
		return nil;
	}
	NSString* type = [dictionary objectForKey:@"type"];
	if ([type isEqualToString:WLCandyTypeConversation]) {
		return [[WLConversation alloc] initWithDictionary:dictionary error:NULL];
	} else {
		return [[WLImage alloc] initWithDictionary:dictionary error:NULL];
	}
}

- (void)addComment:(WLComment *)comment {
	if (!self.comments) {
		self.comments = (id)[NSArray arrayWithObject:comment];
	} else {
		self.comments = (id)[self.comments arrayByAddingObject:comment];
	}
}

@end
