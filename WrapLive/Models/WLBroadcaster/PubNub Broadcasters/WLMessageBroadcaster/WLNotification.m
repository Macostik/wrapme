//
//  WLNotification.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLNotification.h"
#import "NSDictionary+Extended.h"
#import "WLWrap.h"
#import "WLCandy.h"
#import "WLComment.h"
#import "NSString+Additions.h"

@implementation WLNotification

+ (instancetype)notificationWithMessage:(PNMessage*)message {
	return [self notificationWithData:message.message];
}

+ (instancetype)notificationWithData:(NSDictionary *)data {
	if ([data isKindOfClass:[NSDictionary class]]) {
		NSString* type = [data objectForKey:@"pn_type"];
		if (type) {
			WLNotification* notification = [[self alloc] init];
			notification.type = [type integerValue];
			notification.data = data;
			return notification;
		}
	}
	return nil;
}

- (WLWrap *)wrap {
	if (!_wrap) {
		NSString* identifier = [self.data stringForKey:@"wrap_uid"];
		if (identifier.nonempty) {
			_wrap = [[WLWrap alloc] init];
			_wrap.identifier = identifier;
		}
	}
	return _wrap;
}

- (WLCandy *)candy {
	if (!_candy) {
		NSString* identifier = [self.data stringForKey:@"candy_uid"];
		if (identifier.nonempty) {
			_candy = [[WLCandy alloc] init];
			_candy.identifier = identifier;
		}
	}
	return _candy;
}

- (WLComment *)comment {
	if (!_comment) {
		NSString* identifier = [self.data stringForKey:@"comment_uid"];
		if (identifier.nonempty) {
			_comment = [[WLComment alloc] init];
			_comment.identifier = identifier;
		}
	}
	return _comment;
}

@end
