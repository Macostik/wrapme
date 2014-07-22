//
//  WLWrapRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapRequest.h"
#import "WLWrapBroadcaster.h"

@implementation WLWrapRequest

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@", self.wrap.identifier];
}

+ (instancetype)request:(WLWrap *)wrap page:(NSInteger)page {
    WLWrapRequest* request = [WLWrapRequest request];
    request.wrap = wrap;
    request.page = page;
    return request;
}

+ (instancetype)request:(WLWrap *)wrap {
    return [self request:wrap page:1];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    if (self.page == 0) {
        self.page = 1;
    }
    [parameters trySetObject:@([[NSTimeZone localTimeZone] secondsFromGMT]) forKey:@"utc_offset"];
	[parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
	[parameters trySetObject:@(self.page) forKey:@"group_by_date_page_number"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    return [self.wrap update:response.data[@"wrap"]];
}

- (void)handleFailure:(NSError *)error {
    if (self.wrap.uploaded && error.isContentUnavaliable) {
        [self.wrap remove];
        self.wrap = nil;
    }
    [super handleFailure:error];
}

@end
