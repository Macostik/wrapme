//
//  WLComment.m
//  moji
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLComment+Extended.h"
#import "WLEntryManager.h"
#import "WLEntryNotifier.h"

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
	return [dictionary stringForKey:WLCommentUIDKey];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
}

- (void)prepareForDeletion {
    [self.candy removeComment:self];
    [super prepareForDeletion];
}

- (BOOL)deletable {
    return self.contributedByCurrentUser || self.candy.deletable;
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    NSString* text = [dictionary stringForKey:WLContentKey];
    if (!NSStringEqual(self.text, text)) self.text = text;
    WLCandy* currentCandy = self.candy;
    WLCandy *candy = relatedEntry ? : (currentCandy ? : [WLCandy entry:[dictionary stringForKey:WLCandyUIDKey]]);
    if (currentCandy != candy) self.candy = candy;
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (BOOL)canBeUploaded {
    return self.candy.uploaded && self.uploading;
}

- (WLPicture *)picture {
    return self.candy.picture;
}

@end
