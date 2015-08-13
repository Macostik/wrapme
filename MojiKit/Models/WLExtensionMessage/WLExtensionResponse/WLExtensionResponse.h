//
//  WLExtensionsResponseMessage.h
//  moji
//
//  Created by Ravenpod on 7/8/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLExtensionMessage.h"

@interface WLExtensionResponse : WLExtensionMessage

@property (nonatomic) BOOL success;

@property (strong, nonatomic) NSString *message;

+ (instancetype)success;

+ (instancetype)failure;

+ (instancetype)successWithUserInfo:(NSDictionary *)userInfo;

+ (instancetype)successWithMessage:(NSString*)message;

+ (instancetype)failureWithMessage:(NSString*)message;

+ (instancetype)successWithMessage:(NSString*)message userInfo:(NSDictionary *)userInfo;

+ (instancetype)failureWithMessage:(NSString*)message userInfo:(NSDictionary *)userInfo;

+ (instancetype)responseWithSuccess:(BOOL)success message:(NSString*)message userInfo:(NSDictionary *)userInfo;

@end
