//
//  WLConversation.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLConversation.h"
#import "WLComment.h"
#import "WLUser.h"
#import "WLPicture.h"

@implementation WLConversation

+ (instancetype)entry {
	WLConversation *conversation = [super entry];
	conversation.type = WLCandyTypeConversation;
	return conversation;
}

- (NSString *)cover {
	NSString* cover = [super cover];
	if (cover.length > 0) {
		return cover;
	}
	WLComment* comment = [self.comments lastObject];
	return comment.author.avatar.thumbnail;
}

@end
