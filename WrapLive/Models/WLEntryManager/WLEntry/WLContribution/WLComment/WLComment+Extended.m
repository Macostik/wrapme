//
//  WLComment.m
//  WrapLive
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
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

- (void)remove {
    [self.candy removeComment:self];
    [self notifyOnDeleting];
    [super remove];
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
    return self.candy.uploaded && !self.isFirst;
}

- (void)touch:(NSDate *)date {
    [self.candy touch:date];
    [super touch:date];
}

- (WLPicture *)picture {
    return self.candy.picture;
}

- (WLEntry *)containingEntry {
    return self.candy;
}

- (void)setContainingEntry:(WLEntry *)containingEntry {
    if (containingEntry && self.candy != containingEntry) {
        self.candy = (id)containingEntry;
    }
}

@end
