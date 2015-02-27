//
//  WLUpdateContributorsRequest.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/10/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUpdateContributorsRequest.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLEntryNotifier.h"

@implementation WLUpdateContributorsRequest

+ (instancetype)request:(WLWrap *)wrap {
    WLUpdateContributorsRequest* request = [WLUpdateContributorsRequest request];
    request.wrap = wrap;
    
    return request;
}

- (NSString *)method {
    return self.isAddContirbutor ? @"POST" : @"DELETE";
}

- (NSString *)path {
    return [NSString stringWithFormat:@"wraps/%@/%@", self.wrap.identifier, self.isAddContirbutor ? @"add_contributor" : @"remove_contributor"];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    NSMutableArray* contributors = [NSMutableArray array];
	NSMutableArray* invitees = [NSMutableArray array];
    for (WLAddressBookPhoneNumber *_person in self.contributors) {
        if (_person.user) {
            [contributors addObject:_person.user.identifier];
        } else {
            NSData* invitee = [NSJSONSerialization dataWithJSONObject:@{@"name":WLString(_person.name),@"phone_number":_person.phone} options:0 error:NULL];
            [invitees addObject:[[NSString alloc] initWithData:invitee encoding:NSUTF8StringEncoding]];
        }
    }
	[parameters trySetObject:contributors forKey:@"user_uids"];
	[parameters trySetObject:invitees forKey:@"invitees"];
   
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap* wrap = self.wrap;
    return wrap.valid ? [wrap update:response.data[WLWrapKey]] : nil;
}

@end
