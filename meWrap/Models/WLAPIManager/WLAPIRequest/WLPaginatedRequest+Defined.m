//
//  WLAPIRequest+Wraps.m
//  meWrap
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest+Defined.h"

@implementation WLPaginatedRequest (Defined)

// TODO: add mutable property

+ (instancetype)wraps:(NSString *)scope {
    return [[[self GET:@"wraps", nil] parametrize:^(WLPaginatedRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:scope forKey:@"scope"];
    }] parse:^(Response *response, WLObjectBlock success, WLFailureBlock failure) {
        NSArray* wraps = [Wrap mappedEntries:[Wrap prefetchArray:[response.data arrayForKey:@"wraps"]]];
        [[WLWhatsUpSet sharedSet] update:nil failure:nil];
        success(wraps);
    }];
}

+ (instancetype)candies:(Wrap *)wrap {
    return [[[self alloc] init] candies:wrap];
}

+ (instancetype)messages:(Wrap *)wrap {
    return [[[self GET:@"wraps/%@/chats", wrap.identifier] parse:^(Response *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSArray* messages = [Message mappedEntries:[Message prefetchArray:response.data[@"chats"]] container:wrap];
            if (messages.nonempty) {
                [wrap notifyOnUpdate:EntryUpdateEventContentAdded];
            }
            success(messages);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if ([error isResponseError:ResponseCodeContentUnavailable] && wrap.valid && wrap.uploaded) {
            [wrap remove];
        }
    }];
}

- (instancetype)candies:(Wrap *)wrap {
    self.path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
    [[[self parametrize:^(WLPaginatedRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
    }] parse:^(Response *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            success([Candy mappedEntries:[Candy prefetchArray:response.data[WLCandiesKey]] container:wrap]);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
    return self;
}

+ (instancetype)wrap:(Wrap *)wrap contentType:(NSString *)contentType {
    return [[[[self GET:@"wraps/%@", wrap.identifier] parametrize:^(WLPaginatedRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
        [parameters trySetObject:contentType forKey:@"pick"];
        if (request.type == WLPaginatedRequestTypeNewer && request.newer) {
            [parameters trySetObject:@"newer_than" forKey:@"condition"];
            [parameters trySetObject:@([request.newer endOfDay].timestamp) forKey:@"offset_in_epoch"];
        } else if (request.type == WLPaginatedRequestTypeOlder && request.older) {
            [parameters trySetObject:@"older_than" forKey:@"condition"];
            [parameters trySetObject:@([request.older startOfDay].timestamp) forKey:@"offset_in_epoch"];
        }
    }] parse:^(Response *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            success(@[[wrap update:[Wrap prefetchDictionary:response.data[WLWrapKey]]]]);
        } else {
            success(nil);
        }
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && [error isResponseError:ResponseCodeContentUnavailable]) {
            [wrap remove];
        }
    }];
}

@end
