//
//  WLUploadWrapRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadWrapRequest.h"
#import "WLEntryNotifier.h"

@implementation WLUploadWrapRequest

- (NSString *)method {
    return @"PUT";
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@", self.wrap.identifier];
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap* wrap = self.wrap;
    if (wrap.valid) {
        wrap = [wrap API_setup:response.data[WLWrapKey]];
        [wrap notifyOnUpdate];
        return wrap;
    } else {
        return nil;
    }
}

- (void)handleFailure:(NSError *)error {
    [super handleFailure:error];
    if (self.wrap.uploaded && error.isContentUnavaliable) {
        [self.wrap remove];
        self.wrap = nil;
    }
}


@end
