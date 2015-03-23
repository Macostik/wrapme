//
//  WLExtensionManager.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/2/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "AFURLSessionManager.h"
#import <AFNetworking.h>
#import "DefinedBlocks.h"

static NSInteger WLAuthorizedError = 401;
static NSInteger WLNoError = 0;

@interface WLExtensionManager : AFHTTPSessionManager

@property (nonatomic) BOOL authorized;

+ (instancetype)instance;

- (NSURLSessionDataTask *)posts:(WLArrayBlock)success failure:(WLFailureBlock)failure;

- (NSURLSessionDataTask *)signIn:(WLBlock)success failure:(WLFailureBlock)failure;

@end
