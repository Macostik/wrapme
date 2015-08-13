//
//  WLMessage+Extended.m
//  moji
//
//  Created by Ravenpod on 9/8/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMessage+Extended.h"
#import "WLEntryManager.h"
#import "WLEntryNotifier.h"

@implementation WLMessage (Extended)

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:@"chat_uid"];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    NSString* text = [dictionary stringForKey:WLContentKey];
    if (!NSStringEqual(self.text, text)) self.text = text;
    WLWrap* currentWrap = self.wrap;
    WLWrap* wrap = relatedEntry ? : (currentWrap ? : [WLWrap entry:[dictionary stringForKey:WLWrapUIDKey]]);
    if (wrap != currentWrap) self.wrap = wrap;
    return self;
}

- (WLPicture *)picture {
    return self.contributor.picture;
}

- (void)prepareForDeletion {
    [self.wrap removeMessage:self];
    [super prepareForDeletion];
}

@end
