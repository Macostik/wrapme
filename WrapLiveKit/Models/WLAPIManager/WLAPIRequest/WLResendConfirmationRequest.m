//
//  WLResendConfirmationRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLResendConfirmationRequest.h"

@implementation WLResendConfirmationRequest

+ (NSString *)defaultMethod {
    return @"POST";
}

- (NSString *)path {
    return @"users/resend_confirmation";
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    [parameters trySetObject:self.email forKey:WLEmailKey];
    return [super configure:parameters];
}

@end
