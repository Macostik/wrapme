//
//  WLAddWrapRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddWrapRequest.h"
#import "WLEntryNotifier.h"

@implementation WLAddWrapRequest

- (NSString *)method {
    return @"POST" ;
}

- (NSString *)path {
    return  @"wraps";
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap *wrap = [super objectInResponse:response];
    return [wrap notifyOnAddition:nil];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [super configure:parameters];
    WLWrap* wrap = self.wrap;
    [parameters trySetObject:wrap.uploadIdentifier forKey:@"upload_uid"];
    [parameters trySetObject:@(wrap.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    return parameters;
}

@end
