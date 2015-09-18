//
//  WLAPIRequest+Wraps.m
//  meWrap
//
//  Created by Ravenpod on 7/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPaginatedRequest+Defined.h"
#import "WLEntryNotifier.h"

@implementation WLPaginatedRequest (Defined)

+ (instancetype)wraps:(NSString *)scope {
    return [[[self GET:@"wraps", nil] parametrize:^(WLPaginatedRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:scope forKey:@"scope"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        NSSet* wraps = [WLWrap API_entries:[response.data arrayForKey:@"wraps"]];
        for (WLWrap *wrap in wraps) {
            if (!wrap.isPublic) {
                [[WLUser currentUser] addWraps:wraps];
            }
        }
        success(wraps);
    }];
}

+ (instancetype)candies:(WLWrap *)wrap {
    return [[[self alloc] init] candies:wrap];
}

+ (instancetype)messages:(WLWrap *)wrap {
    return [[[[self GET:@"wraps/%@/chats", wrap.identifier] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSSet* messages = [WLMessage API_entries:response.data[@"chats"] container:wrap];
            if (messages.nonempty) {
                [wrap notifyOnUpdate];
            }
            success(messages);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if ([error isError:WLErrorContentUnavaliable] && wrap.valid && wrap.uploaded) {
            [wrap remove];
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

- (instancetype)candies:(WLWrap *)wrap {
    self.path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
    [[[self parametrize:^(WLPaginatedRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            NSSet* candies = [WLCandy API_entries:response.data[WLCandiesKey] container:wrap];
            [wrap addCandies:candies];
            success(candies);
        } else {
            success(nil);
        }
    }] afterFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
    return self;
}

+ (instancetype)wrap:(WLWrap *)wrap contentType:(NSString *)contentType {
    return [[[[self GET:@"wraps/%@", wrap.identifier] parametrize:^(WLPaginatedRequest *request, NSMutableDictionary *parameters) {
        [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
        [parameters trySetObject:contentType forKey:@"pick"];
        if (request.type == WLPaginatedRequestTypeNewer && request.newer) {
            [parameters trySetObject:@"newer_than" forKey:@"condition"];
            [parameters trySetObject:@([request.newer endOfDay].timestamp) forKey:@"offset_in_epoch"];
        } else if (request.type == WLPaginatedRequestTypeOlder && request.older) {
            [parameters trySetObject:@"older_than" forKey:@"condition"];
            [parameters trySetObject:@([request.older beginOfDay].timestamp) forKey:@"offset_in_epoch"];
        }
    }] parse:^(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure) {
        if (wrap.valid) {
            success([wrap update:response.data[WLWrapKey]]);
        } else {
            success(nil);
        }
    }] beforeFailure:^(NSError *error) {
        if (wrap.uploaded && error.isContentUnavaliable) {
            [wrap remove];
        }
    }];
}

@end
