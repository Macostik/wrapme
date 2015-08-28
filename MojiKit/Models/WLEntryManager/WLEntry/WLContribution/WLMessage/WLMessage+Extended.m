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

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    [super API_setup:dictionary container:container];
    NSString* text = [dictionary stringForKey:WLContentKey];
    if (!NSStringEqual(self.text, text)) self.text = text;
    self.container = container ? : (self.wrap ? : [WLWrap entry:[dictionary stringForKey:WLWrapUIDKey]]);
    return self;
}

- (WLPicture *)picture {
    return self.contributor.picture;
}

- (void)prepareForDeletion {
    [self.wrap removeMessagesObject:self];
    [super prepareForDeletion];
}

@end
