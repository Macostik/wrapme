//
//  WLAPIRequest.h
//  meWrap
//
//  Created by Ravenpod on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

@class WLAPIRequest, Response;

@interface WLAPIManager : AFHTTPRequestOperationManager

+ (instancetype)manager;

- (NSString*)urlWithPath:(NSString*)path;

@end

typedef void (^WLAPIRequestParser) (Response *response, ObjectBlock success, FailureBlock failure);

typedef void (^WLAPIRequestParametrizer) (id request, NSMutableDictionary* parameters);

typedef BOOL (^WLAPIRequestFailureValidator) (id request, NSError *error);

typedef void (^WLAPIRequestUnauthorizedErrorBlock) (WLAPIRequest *request, NSError *error);

typedef NSString *(^WLAPIRequestFile) (id request);

@interface WLAPIRequest : NSObject

@property (strong, nonatomic) NSString* method;

@property (strong, nonatomic) NSString* path;

@property (strong, nonatomic) WLAPIRequestParser parser;

@property (strong, nonatomic) NSMutableArray *parametrizers;

@property (strong, nonatomic) ObjectBlock successBlock;

@property (strong, nonatomic) FailureBlock beforeFailure;

@property (strong, nonatomic) FailureBlock failureBlock;

@property (strong, nonatomic) FailureBlock afterFailure;

@property (strong, nonatomic) WLAPIRequestFailureValidator failureValidator;

@property (weak, nonatomic) AFHTTPRequestOperation *operation;

@property (readonly, nonatomic) BOOL loading;

@property (nonatomic) NSTimeInterval timeout;

@property (nonatomic) BOOL skipReauthorizing;

@property (strong, nonatomic) WLAPIRequestFile file;

+ (instancetype)request;

+ (NSTimeInterval)timeout;

+ (instancetype)GET;

+ (instancetype)POST;

+ (instancetype)PUT;

+ (instancetype)DELETE;

- (instancetype)path:(NSString*)path, ...;

+ (void)setUnauthorizedErrorBlock:(WLAPIRequestUnauthorizedErrorBlock)unauthorizedErrorBlock;

- (instancetype)parse:(WLAPIRequestParser)parser;

- (instancetype)parametrize:(WLAPIRequestParametrizer)parametrizer;

- (instancetype)forceParametrize:(WLAPIRequestParametrizer)parametrizer;

- (instancetype)file:(WLAPIRequestFile)file;

- (instancetype)beforeFailure:(FailureBlock)beforeFailure;

- (instancetype)afterFailure:(FailureBlock)afterFailure;

- (instancetype)validateFailure:(WLAPIRequestFailureValidator)validateFailure;

- (NSMutableDictionary *)parametrize;

- (NSMutableURLRequest*)request:(NSMutableDictionary*)parameters url:(NSString*)url;

- (id)send:(ObjectBlock)success failure:(FailureBlock)failure;

- (id)send;

- (void)handleSuccess:(id)object;

- (void)handleFailure:(NSError*)error;

- (void)cancel;

@end
