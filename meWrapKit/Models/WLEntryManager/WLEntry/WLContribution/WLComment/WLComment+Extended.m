//
//  WLComment.m
//  meWrap
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

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    NSString* text = [dictionary stringForKey:WLContentKey];
    if (!NSStringEqual(self.text, text)) self.text = text;
    self.container = container ? : (self.candy ? : [WLCandy entry:[dictionary stringForKey:WLCandyUIDKey]]);
    return [super API_setup:dictionary container:container];
}

- (BOOL)canBeUploaded {
    return self.candy.uploaded && self.uploading;
}

- (WLPicture *)picture {
    return self.candy.picture;
}

@end
