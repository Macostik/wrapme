//
//  WLAPIRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+Extended.h"
#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"
#import "WLAPIResponse.h"
#import "WLAPIManager.h"

@interface WLAPIRequest : NSObject

@property (strong, nonatomic) NSString* method;

@property (readonly, nonatomic) NSString* path;

@property (readonly, nonatomic) WLAPIManager* manager;

@property (strong, nonatomic) WLObjectBlock successBlock;

@property (strong, nonatomic) WLFailureBlock failureBlock;

@property (weak, nonatomic) AFHTTPRequestOperation *operation;

@property (readonly, nonatomic) BOOL loading;

@property (nonatomic) NSTimeInterval timeout;

+ (instancetype)request;

+ (NSString*)defaultMethod;

+ (NSTimeInterval)timeout;

- (NSMutableDictionary *)configure:(NSMutableDictionary*)parameters;

- (NSMutableURLRequest*)request:(NSMutableDictionary*)parameters url:(NSString*)url;

- (id)send:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)send;

- (id)objectInResponse:(WLAPIResponse*)response;

- (void)handleSuccess:(id)object;

- (void)handleFailure:(NSError*)error;

- (void)cancel;

@end

@interface NSDate (WLServerTime)

+ (instancetype)now;

+ (instancetype)now:(NSTimeInterval)offset;

@end
