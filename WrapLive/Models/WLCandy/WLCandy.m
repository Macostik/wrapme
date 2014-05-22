//
//  WLCandy.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy.h"
#import "WLComment.h"
#import "WLWrapBroadcaster.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"

@implementation WLCandy

+ (instancetype)chatMessageWithText:(NSString *)text {
	WLCandy* candy = [self entry];
	candy.type = WLCandyTypeChatMessage;
	candy.chatMessage = text;
	return candy;
}

+ (instancetype)imageWithPicture:(WLPicture *)picture {
	WLCandy* candy = [self entry];
	candy.type = WLCandyTypeImage;
	candy.picture = picture;
	return candy;
}

+ (instancetype)imageWithFileAtPath:(NSString *)path {
	WLCandy* candy = [self entry];
	candy.type = WLCandyTypeImage;
	candy.picture.large = path;
	candy.picture.medium = path;
	candy.picture.small = path;
	return candy;
}

- (id)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err {
    self = [super initWithDictionary:dict error:err];
    if (self) {
        self.comments = (id)[[self.comments reverseObjectEnumerator] allObjects];
    }
    return self;
}

+ (NSDictionary*)pictureMapping {
	return @{@"large":@[@"large_image_attachment_url"],
			 @"medium":@[@"medium_sq_image_attachment_url"],
			 @"small":@[@"small_sq_image_attachment_url"]};
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

- (void)removeComment:(WLComment *)comment {
	self.comments = (id)[self.comments entriesByRemovingEntry:comment];
	self.updatedAt = [NSDate date];
	[comment broadcastRemoving];
	[self broadcastChange];
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

- (BOOL)isEqualToEntry:(WLCandy *)candy {
	if (self.identifier.nonempty && candy.identifier.nonempty) {
		return [super isEqualToEntry:candy];
	}
	if (self.type == WLCandyTypeImage) {
		return [self.picture.large isEqualToString:candy.picture.large];
	} else {
		return [self.chatMessage isEqualToString:candy.chatMessage] &&
		[self.updatedAt compare:candy.updatedAt] == NSOrderedSame;
	}
}

- (instancetype)updateWithObject:(id)object {
	WLCandy* candy = [super updateWithObject:object];
	[candy broadcastChange];
	return candy;
}

@end
