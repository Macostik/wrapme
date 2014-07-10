//
//  WLComment.m
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLComment+Extended.h"
#import "WLEntryManager.h"
#import "WLWrapBroadcaster.h"

@implementation WLComment (Extended)

+ (NSNumber *)uploadingOrder {
    return @3;
}

+ (instancetype)comment:(NSString *)text {
    WLComment* comment = [self contribution];
    comment.text = text;
    return comment;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:@"comment_uid"];
}

- (void)remove {
    [self.candy removeComment:self];
    [super remove];
    [self broadcastRemoving];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    self.text = [dictionary stringForKey:@"content"];
    self.candy = relatedEntry ? : (self.candy ? : [WLCandy entry:[dictionary stringForKey:@"candy_uid"]]);
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (BOOL)canBeUploaded {
    return self.candy.uploading == nil;
}

- (void)touch:(NSDate *)date {
    [self.candy touch:date];
    [super touch:date];
}

@end
