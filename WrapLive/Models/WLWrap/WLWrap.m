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
#import "WLPicture.h"
#import "NSArray+Additions.h"
#import "WLUser.h"

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

+ (JSONKeyMapper *)keyMapper {
	return [[JSONKeyMapper alloc] initWithDictionary:@{@"wrap_uid":@"wrapID",
													   @"created_at_in_epoch":@"createdAt",
													   @"updated_at_in_epoch":@"updatedAt"}];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
		self.cover = [[WLPicture alloc] initWithDictionary:dict error:err];
        self.candies = [self.candies map:^id(id item) {
			return [WLCandy candyWithDictionary:item];
		}];
    }
    return self;
}

- (void)addCandy:(WLCandy *)candy {
	NSMutableArray* candies = [NSMutableArray arrayWithArray:self.candies];
	[candies insertObject:candy atIndex:0];
	self.candies = [candies copy];
	self.updatedAt = [NSDate date];
}

- (WLPicture *)cover {
	if (!_cover) {
		_cover = [[WLPicture alloc] init];
	}
	return _cover;
}

- (void)contributorNames:(void (^)(NSString *))completion {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSString* names = [[self.contributors map:^id(WLUser* contributor) {
			return contributor.name;
		}] componentsJoinedByString:@", "];
        dispatch_async(dispatch_get_main_queue(), ^{
			completion(names);
        });
    });
}

@end
