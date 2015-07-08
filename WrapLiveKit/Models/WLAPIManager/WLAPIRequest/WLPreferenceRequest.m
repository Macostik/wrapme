//
//  WLPreferenceRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 07/07/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLPreferenceRequest.h"

@implementation WLPreferenceRequest

+ (instancetype)request:(WLWrap *)wrap {
    WLPreferenceRequest* request = [self request];
    request.wrap = wrap;
    return request;
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/preferences", self.wrap.identifier];
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
