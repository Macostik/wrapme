//
//  WLUploadWrapRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/16/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUploadWrapRequest.h"
#import "WLPerson.h"
#import "WLWrapBroadcaster.h"

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
    self.filePath = self.wrap.picture.large;
    WLWrap* wrap = self.wrap;
    NSMutableArray* contributors = [NSMutableArray array];
	NSMutableArray* invitees = [NSMutableArray array];
	for (WLUser* contributor in wrap.contributors) {
		if (self.creation) {
            if (![contributor isCurrentUser]) {
                [contributors addObject:contributor.identifier];
            }
        } else {
            [contributors addObject:contributor.identifier];
        }
	}
    for (WLPerson * person in wrap.invitees) {
        NSData* invitee = [NSJSONSerialization dataWithJSONObject:@{@"name":WLString(person.name),@"phone_number":person.phone} options:0 error:NULL];
        [invitees addObject:[[NSString alloc] initWithData:invitee encoding:NSUTF8StringEncoding]];
    }
	[parameters trySetObject:wrap.name forKey:@"name"];
	[parameters trySetObject:contributors forKey:@"user_uids"];
	[parameters trySetObject:invitees forKey:@"invitees"];
    if (self.creation) {
        [parameters trySetObject:wrap.uploadIdentifier forKey:@"upload_uid"];
        [parameters trySetObject:@(wrap.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
    }
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap* wrap = [self.wrap update:response.data[@"wrap"]];
    if (self.creation) {
        [wrap broadcastCreation];
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
