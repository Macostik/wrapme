//
//  WLDataManager.h
//  WrapLive
//
//  Created by Sergey Maximenko on 29.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLAPIManager.h"

@class WLWrap;

typedef void (^WLDataManagerBlock)(id object, BOOL cached, BOOL stop);

@interface WLDataManager : NSObject

+ (void)wraps:(BOOL)refresh success:(WLDataManagerBlock)success failure:(WLAPIManagerFailureBlock)failure;

+ (void)wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

+ (void)candy:(WLCandy*)candy wrap:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

+ (void)messages:(WLWrap*)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure;

@end
