//
//  WLUser.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUser.h"
#import "WLPicture.h"

@implementation WLUser

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
	self = [super initWithDictionary:dict error:err];
	if (self) {
		self.avatar = [[WLPicture alloc] initWithDictionary:dict error:err];
	}
	return self;
}

+ (JSONKeyMapper *)keyMapper {
	return [[JSONKeyMapper alloc] initWithDictionary:@{@"full_phone_number":@"phoneNumber"}];
}

- (WLPicture *)avatar {
	if (!_avatar) {
		_avatar = [[WLPicture alloc] init];
	}
	return _avatar;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

- (BOOL)isEqualToUser:(WLUser *)user {
	return [self.phoneNumber isEqualToString:user.phoneNumber];
}

@end
