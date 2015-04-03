//
//  WLVarificationCallRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/3/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLVerificationCallRequest.h"
#import "WLAuthorization.h"

@implementation WLVerificationCallRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

- (NSString *)path {
    return @"users/call";
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:[WLAuthorization currentAuthorization].email forKey:WLEmailKey];
    [parameters trySetObject:[WLAuthorization currentAuthorization].deviceUID forKey:@"device_uid"];
    return [super configure:parameters];
}

@end
