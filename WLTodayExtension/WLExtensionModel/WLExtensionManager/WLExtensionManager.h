//
//  WLExtensionManager.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/2/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "AFURLSessionManager.h"
#import <AFNetworking.h>

@interface WLExtensionManager : AFHTTPSessionManager

+ (instancetype)instance;
+ (NSURLSessionDataTask *)postsHandlerBlock:(void (^)(NSArray *posts, NSError *error))block;
+ (NSURLSessionDataTask *)signInHandlerBlock;

@end
