//
//  WLAPIRequest.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+Extended.h"
#import "WLCollections.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"
#import "WLAPIResponse.h"
#import "WLAPIManager.h"

@class WLAPIRequest;

typedef void (^WLAPIRequestMapper)(WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure);

typedef void (^WLAPIRequestParametrizer)(id request, NSMutableDictionary* parameters);

typedef BOOL (^WLAPIRequestFailureValidator)(id request, NSError *error);

@interface WLAPIRequest : NSObject

@property (strong, nonatomic) NSString* method;

@property (strong, nonatomic) NSString* path;

@property (strong, nonatomic) WLAPIRequestMapper mapper;

@property (strong, nonatomic) WLAPIRequestParametrizer parametrizer;

@property (readonly, nonatomic) WLAPIManager* manager;

@property (strong, nonatomic) WLObjectBlock successBlock;

@property (strong, nonatomic) WLFailureBlock beforeFailure;

@property (strong, nonatomic) WLFailureBlock failureBlock;

@property (strong, nonatomic) WLFailureBlock afterFailure;

@property (strong, nonatomic) WLAPIRequestFailureValidator failureValidator;

@property (weak, nonatomic) AFHTTPRequestOperation *operation;

@property (readonly, nonatomic) BOOL loading;

@property (nonatomic) NSTimeInterval timeout;

@property (nonatomic) BOOL skipReauthorizing;

+ (instancetype)request;

+ (NSString*)defaultMethod;

+ (NSTimeInterval)timeout;

+ (instancetype)GET:(NSString*)path, ...;

+ (instancetype)POST:(NSString*)path, ...;

+ (instancetype)PUT:(NSString*)path, ...;

+ (instancetype)DELETE:(NSString*)path, ...;

- (instancetype)map:(WLAPIRequestMapper)mapper;

- (instancetype)parametrize:(WLAPIRequestParametrizer)parametrizer;

- (instancetype)beforeFailure:(WLFailureBlock)beforeFailure;

- (instancetype)afterFailure:(WLFailureBlock)afterFailure;

- (instancetype)validateFailure:(WLAPIRequestFailureValidator)validateFailure;

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
