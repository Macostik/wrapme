//
//  WLBaseOperationWrapRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseOperationWrapRequest.h"
#import "WLPerson.h"


@implementation WLBaseOperationWrapRequest

+ (instancetype)request:(WLWrap *)wrap {
    WLBaseOperationWrapRequest* request = [self request];
    request.wrap = wrap;
    return request;
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
	[parameters trySetObject:self.wrap.name forKey:@"name"];
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap* wrap = self.wrap;
    return wrap.valid ? [self.wrap API_setup:response.data[WLWrapKey]] : nil;
}

@end
