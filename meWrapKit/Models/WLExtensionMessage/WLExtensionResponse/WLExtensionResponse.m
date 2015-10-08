//
//  WLExtensionsResponseMessage.m
//  meWrap\
//
//  Created by Ravenpod on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLExtensionResponse.h"

@implementation WLExtensionResponse

+ (NSSet *)archivableProperties {
    return [NSSet setWithObjects:@"message", @"success", @"userInfo", nil];
}

+ (instancetype)responseWithSuccess:(BOOL)success message:(NSString*)message userInfo:(NSDictionary *)userInfo {
    WLExtensionResponse *response = [[self alloc] init];
    response.success = success;
    response.message = message;
    response.userInfo = userInfo;
    return response;
}

+ (instancetype)success {
    return [self successWithMessage:nil];
}

+ (instancetype)failure {
    return [self failureWithMessage:nil];
}

+ (instancetype)successWithUserInfo:(NSDictionary *)userInfo {
    return [self successWithMessage:nil userInfo:userInfo];
}

+ (instancetype)successWithMessage:(NSString*)message {
    return [self successWithMessage:message userInfo:nil];
}

+ (instancetype)failureWithMessage:(NSString*)message {
    return [self failureWithMessage:message userInfo:nil];
}

+ (instancetype)successWithMessage:(NSString*)message userInfo:(NSDictionary *)userInfo {
    return [self responseWithSuccess:YES message:message userInfo:userInfo];
}

+ (instancetype)failureWithMessage:(NSString*)message userInfo:(NSDictionary *)userInfo {
    return [self responseWithSuccess:NO message:message userInfo:userInfo];
}

+ (NSString*)serializationKey {
    return @"response";
}

@end
