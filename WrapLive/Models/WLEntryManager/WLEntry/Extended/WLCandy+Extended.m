//
//  WLCandy.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCandy+Extended.h"
#import "WLEntryManager.h"
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"

@implementation WLCandy (Extended)

+ (NSNumber *)uploadingOrder {
    return @2;
}

+ (instancetype)candyWithType:(WLCandyType)type wrap:(WLWrap*)wrap {
    WLCandy* candy = [self contribution];
    [wrap addCandy:candy];
    candy.type = @(type);
    return candy;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:@"candy_uid"];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
	[super API_setup:dictionary relatedEntry:relatedEntry];
	self.type = [dictionary numberForKey:@"candy_type"];
	self.message = [dictionary stringForKey:@"chat_message"];
    if (!self.comments) {
        self.comments = [NSMutableOrderedSet orderedSet];
    }
    [WLComment API_entries:[dictionary arrayForKey:@"comments"] relatedEntry:self container:self.comments];
    [self.comments sortEntriesByCreationAscending];
	WLPicture* picture = [[WLPicture alloc] init];
	picture.large = [dictionary stringForKey:@"large_image_attachment_url"];
	picture.medium = [dictionary stringForKey:@"medium_sq_image_attachment_url"];
	picture.small = [dictionary stringForKey:@"small_sq_image_attachment_url"];
	self.picture = picture;
    self.wrap = relatedEntry ? : (self.wrap ? : [WLWrap entry:[dictionary stringForKey:@"wrap_uid"]]);
    return self;
}

- (void)touch {
    [super touch];
    [self.wrap sortCandies];
}

- (BOOL)isCandyOfType:(WLCandyType)type {
    return [self.type integerValue] == type;
}

- (BOOL)isImage {
	return [self isCandyOfType:WLCandyTypeImage];
}

- (BOOL)isMessage {
    return [self isCandyOfType:WLCandyTypeMessage];
}

- (BOOL)belongsToWrap:(WLWrap *)wrap {
    return self.wrap == wrap;
}

- (void)remove {
    [self.wrap removeCandy:self];
    [super remove];
    [self broadcastRemoving];
}

- (void)addComment:(WLComment *)comment {
    if (!comment || [self.comments containsObject:comment]) {
        [self.comments sortEntriesByCreationAscending];
        return;
    }
    comment.candy = self;
    [self.comments addObject:comment];
    [self.comments sortEntriesByCreationAscending];
    [self touch];
    [self.wrap broadcastChange];
    [self broadcastChange];
}

- (void)removeComment:(WLComment *)comment {
    if ([self.comments containsObject:comment]) {
        [self.comments removeObject:comment];
        [self save];
        [self.wrap broadcastChange];
        [self broadcastChange];
    }
}

- (void)uploadComment:(NSString *)text success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    WLComment* comment = [WLComment comment:text];
    [self addComment:comment];
    [[WLUploading uploading:comment] upload:success failure:failure];
    [comment save];
}

- (BOOL)canBeUploaded {
    return self.wrap.uploading == nil;
}

@end

