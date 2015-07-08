//
//  WLUploadPreferenceRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 07/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadPreferenceRequest.h"

@implementation WLUploadPreferenceRequest

+ (NSString *)defaultMethod {
    return @"PUT";
}

+ (instancetype)request:(WLWrap *)wrap {
    WLUploadPreferenceRequest* request = [self request];
    request.wrap = wrap;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/preferences", self.wrap.identifier];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:@(self.candyNotify) forKey:WLCandyNotifiableKey];
    [parameters trySetObject:@(self.chatNotify) forKey:WLChatNotifiableKey];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap* wrap = self.wrap;
    if (wrap.valid) {
        wrap = [wrap notifyOnUpdate:^(id object) {
            NSDictionary *preference = [response.data dictionaryForKey:WLPreferenceKey];
            wrap.isCandyNotifiable = [preference boolForKey:WLCandyNotifiableKey];
            wrap.isChatNotifiable = [preference boolForKey:WLChatNotifiableKey];
        }];
        return wrap;
    }
    return nil;
}

@end
