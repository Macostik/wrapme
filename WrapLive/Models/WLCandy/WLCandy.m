//
//  WLCandy.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy.h"
#import "WLComment.h"

@implementation WLCandy

+ (instancetype)chatMessageWithText:(NSString *)text {
	WLCandy* candy = [self entry];
	candy.type = WLCandyTypeChatMessage;
	candy.chatMessage = text;
	return candy;
}

+ (instancetype)imageWithFileAtPath:(NSString *)path {
	WLCandy* candy = [self entry];
	candy.type = WLCandyTypeImage;
	candy.picture.large = path;
	return candy;
}

+ (NSDictionary*)pictureMapping {
	return @{@"large":@[@"large_image_attachment_url"],
			 @"medium":@[@"medium_image_attachment_url"],
			 @"small":@[@"small_image_attachment_url"],
			 @"thumbnail":@[@"thumb_image_attachment_url"]};
}

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"phone_number":@"phoneNumber",
									@"country_calling_code":@"countryCallingCode",
									@"dob_in_epoch":@"birthdate",
									@"candy_uid":@"identifier",
									@"candy_type":@"type",
									@"chat_message":@"chatMessage"}];
}

- (WLPicture *)picture {
	if (self.type == WLCandyTypeChatMessage) {
		WLComment* comment = [self.comments lastObject];
		return comment.picture;
	}
	return [super picture];
}

- (void)addComment:(WLComment *)comment {
	NSMutableArray* comments = [NSMutableArray arrayWithArray:self.comments];
	[comments addObject:comment];
	self.comments = [comments copy];
	self.updatedAt = [NSDate date];
}

- (WLComment *)addCommentWithText:(NSString *)text {
	WLComment* comment = [WLComment commentWithText:text];
	[self addComment:comment];
	return comment;
}

- (BOOL)isImage {
	return self.type == WLCandyTypeImage;
}

- (BOOL)isChatMessage {
	return self.type == WLCandyTypeChatMessage;
}

@end
