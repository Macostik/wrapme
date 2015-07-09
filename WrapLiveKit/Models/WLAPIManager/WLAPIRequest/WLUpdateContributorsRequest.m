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
    
    NSMutableArray *contributors = [NSMutableArray arrayWithArray:self.contributors];
    
    NSArray* registeredContributors = [self.contributors where:@"user != nil"];
    [contributors removeObjectsInArray:registeredContributors];
    [parameters trySetObject:[registeredContributors valueForKeyPath:@"user.identifier"] forKey:@"user_uids"];
    
    if (self.isAddContirbutor) {
        NSMutableArray *invitees = [NSMutableArray array];
        
        while (contributors.nonempty) {
            WLAddressBookPhoneNumber *_person = [contributors firstObject];
            if (_person.record) {
                NSArray *groupedContributors = [contributors where:@"record == %@", _person.record];
                [invitees addObject:@{@"name":WLString(_person.name),@"phone_numbers":[groupedContributors valueForKey:@"phone"]}];
                [contributors removeObjectsInArray:groupedContributors];
            } else {
                [invitees addObject:@{@"name":WLString(_person.name),@"phone_number":_person.phone}];
                [contributors removeObject:_person];
            }
        }
        [parameters trySetObject:[invitees map:^id(NSDictionary *data) {
            NSData* invitee = [NSJSONSerialization dataWithJSONObject:data options:0 error:NULL];
            return [[NSString alloc] initWithData:invitee encoding:NSUTF8StringEncoding];
        }] forKey:@"invitees"];
    }
   
    return parameters;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    WLWrap* wrap = self.wrap;
    return wrap.valid ? [wrap update:response.data[WLWrapKey]] : nil;
}

@end
