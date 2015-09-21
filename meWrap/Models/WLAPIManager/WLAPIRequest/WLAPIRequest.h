//
//  WLAPIRequest.h
//  meWrap
//
//  Created by Ravenpod on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+Extended.h"
#import "WLCollections.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"
#import "WLAPIResponse.h"
#import "WLEntry+WLAPIRequest.h"
#import "AFHTTPRequestOperation.h"

@class WLAPIRequest;

typedef void (^WLAPIRequestParser) (WLAPIResponse *response, WLObjectBlock success, WLFailureBlock failure);

typedef void (^WLAPIRequestParametrizer) (id request, NSMutableDictionary* parameters);

typedef BOOL (^WLAPIRequestFailureValidator) (id request, NSError *error);

typedef void (^WLAPIRequestUnauthorizedErrorBlock) (WLAPIRequest *request, NSError *error);

typedef NSString *(^WLAPIRequestFile) (id request);

@interface WLAPIRequest : NSObject

@property (strong, nonatomic) NSString* method;

@property (strong, nonatomic) NSString* path;

@property (strong, nonatomic) WLAPIRequestParser parser;

@property (strong, nonatomic) NSMutableArray *parametrizers;

@property (strong, nonatomic) WLObjectBlock successBlock;

@property (strong, nonatomic) WLFailureBlock beforeFailure;

@property (strong, nonatomic) WLFailureBlock failureBlock;

@property (strong, nonatomic) WLFailureBlock afterFailure;

@property (strong, nonatomic) WLAPIRequestFailureValidator failureValidator;

@property (weak, nonatomic) AFHTTPRequestOperation *operation;

@property (readonly, nonatomic) BOOL loading;

@property (nonatomic) NSTimeInterval timeout;

@property (nonatomic) BOOL skipReauthorizing;

@property (strong, nonatomic) WLAPIRequestFile file;

+ (instancetype)request;

+ (NSTimeInterval)timeout;

+ (instancetype)GET:(NSString*)path, ...;

+ (instancetype)POST:(NSString*)path, ...;

+ (instancetype)PUT:(NSString*)path, ...;

+ (instancetype)DELETE:(NSString*)path, ...;

+ (void)setUnauthorizedErrorBlock:(WLAPIRequestUnauthorizedErrorBlock)unauthorizedErrorBlock;

- (instancetype)parse:(WLAPIRequestParser)parser;

- (instancetype)parametrize:(WLAPIRequestParametrizer)parametrizer;

- (instancetype)file:(WLAPIRequestFile)file;

- (instancetype)beforeFailure:(WLFailureBlock)beforeFailure;

- (instancetype)afterFailure:(WLFailureBlock)afterFailure;

- (instancetype)validateFailure:(WLAPIRequestFailureValidator)validateFailure;

- (NSMutableDictionary *)parametrize;

- (NSMutableURLRequest*)request:(NSMutableDictionary*)parameters url:(NSString*)url;

- (id)send:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (id)send;

- (void)handleSuccess:(id)object;

- (void)handleFailure:(NSError*)error;

- (void)cancel;

@end
