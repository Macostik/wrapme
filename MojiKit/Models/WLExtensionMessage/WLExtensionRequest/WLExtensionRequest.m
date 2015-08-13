//
//  WLExtensionsRequestMessage.m
//  moji
//
//  Created by Ravenpod on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLExtensionRequest.h"

@implementation WLExtensionRequest

+ (instancetype)requestWithAction:(NSString *)action userInfo:(NSDictionary *)userInfo {
    WLExtensionRequest *request = [[self alloc] init];
    request.action = action;
    request.userInfo = userInfo;
    return request;
}

+ (NSString*)serializationKey {
    return @"request";
}

@end
