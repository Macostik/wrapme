//
//  WLMessagesRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMessagesRequest.h"
#import "WLEntryNotifier.h"

@implementation WLMessagesRequest

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/chats", self.wrap.identifier];
}

+ (instancetype)request:(WLWrap *)wrap {
    WLMessagesRequest* request = [WLMessagesRequest request];
    request.wrap = wrap;
    return request;
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    if (self.latest) {
        [parameters trySetObject:@"latest" forKey:@"latest"];
    }
    return [super configure:parameters];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    NSOrderedSet* messages = [WLMessage API_entries:response.data[@"chats"] relatedEntry:self.wrap];
    if (messages.nonempty) {
        [self.wrap notifyOnUpdate];
    }
    return messages;
}

@end
