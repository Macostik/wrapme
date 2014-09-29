//
//  WLUploadWrapRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadWrapRequest.h"
#import "WLPerson.h"
#import "WLEntryNotifier.h"

@implementation WLUploadWrapRequest

+ (instancetype)request:(WLWrap *)wrap {
    WLUploadWrapRequest* request = [WLUploadWrapRequest request];
    request.wrap = wrap;
    request.creation = !wrap.uploaded;
    return request;
}

- (NSString *)method {
    return self.creation ? @"POST" : @"PUT";
}

- (NSString *)path {
    return self.creation ? @"wraps" : [NSString stringWithFormat:@"wraps/%@", self.wrap.identifier];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    WLWrap* wrap = self.wrap;
	[parameters trySetObject:wrap.name forKey:@"name"];
    if (self.creation) {
        [parameters trySetObject:wrap.uploadIdentifier forKey:@"upload_uid"];
        [parameters trySetObject:@(wrap.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
	WLWrap* wrap = [self.wrap API_setup:response.data[@"wrap"]];
    if (self.creation) {
        [wrap notifyOnAddition];
    } else if (wrap.hasChanges) {
        [wrap notifyOnUpdate];
    }
    return wrap;
}

- (void)handleFailure:(NSError *)error {
    if (!self.creation && self.wrap.uploaded && error.isContentUnavaliable) {
        [self.wrap remove];
        self.wrap = nil;
    }
    [super handleFailure:error];
}

@end
