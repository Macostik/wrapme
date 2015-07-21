//
//  WLAPIRequest.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"
#import "WLAuthorizationRequest.h"
#import "WLWelcomeViewController.h"
#import "NSDate+Formatting.h"
#import "WLSession.h"

static NSString* WLServerTimeDifference = @"WLServerTimeDifference";

@implementation NSDate (WLServerTime)

static NSTimeInterval _difference = 0;

+ (NSTimeInterval)serverTimeDifference {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _difference = [WLSession wl_double:WLServerTimeDifference];
    });
    return _difference;
}

+ (void)setServerTimeDifference:(NSTimeInterval)interval {
    if (_difference != interval) {
        _difference = interval;
        [WLSession setDouble:interval key:WLServerTimeDifference];
    }
}

+ (void)trackServerTime:(NSDate *)serverTime {
    [self setServerTimeDifference:serverTime ? [serverTime timeIntervalSinceNow] : 0];
}

+ (NSDate*)now {
    return [self dateWithTimeIntervalSinceNow:[self serverTimeDifference]];
}

+ (instancetype)now:(NSTimeInterval)offset {
    return [self dateWithTimeIntervalSinceNow:[self serverTimeDifference] + offset];
}

@end

@implementation WLAPIRequest

+ (instancetype)request {
    return [[self alloc] init];
}

+ (NSString *)defaultMethod {
    return @"GET";
}

+ (NSTimeInterval)timeout {
    return 45;
}

+ (instancetype)GET:(NSString*)path, ... {
    BEGIN_ARGUMENTS(path)
    WLAPIRequest *request = [[self alloc] init];
    request.path = [[NSString alloc] initWithFormat:path arguments:args];
    request.method = @"GET";
    END_ARGUMENTS
    return request;
}

+ (instancetype)POST:(NSString*)path, ... {
    BEGIN_ARGUMENTS(path)
    WLAPIRequest *request = [[self alloc] init];
    request.path = [[NSString alloc] initWithFormat:path arguments:args];
    request.method = @"POST";
    END_ARGUMENTS
    return request;
}

+ (instancetype)PUT:(NSString*)path, ... {
    BEGIN_ARGUMENTS(path)
    WLAPIRequest *request = [[self alloc] init];
    request.path = [[NSString alloc] initWithFormat:path arguments:args];
    request.method = @"PUT";
    END_ARGUMENTS
    return request;
}

+ (instancetype)DELETE:(NSString*)path, ... {
    BEGIN_ARGUMENTS(path)
    WLAPIRequest *request = [[self alloc] init];
    request.path = [[NSString alloc] initWithFormat:path arguments:args];
    request.method = @"DELETE";
    END_ARGUMENTS
    return request;
}

- (instancetype)map:(WLAPIRequestMapper)mapper {
    self.mapper = mapper;
    return self;
}

- (instancetype)parametrize:(WLAPIRequestParametrizer)parametrizer {
    self.parametrizer = parametrizer;
    return self;
}

- (instancetype)beforeFailure:(WLFailureBlock)beforeFailure {
    self.beforeFailure = beforeFailure;
    return self;
}

- (instancetype)afterFailure:(WLFailureBlock)afterFailure {
    self.afterFailure = afterFailure;
    return self;
}

- (instancetype)validateFailure:(WLAPIRequestFailureValidator)validateFailure {
    self.failureValidator = validateFailure;
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.method = [[self class] defaultMethod];
        self.timeout = [[self class] timeout];
    }
    return self;
}

- (WLAPIManager *)manager {
    return [WLAPIManager manager];
}

- (NSMutableDictionary *)configure:(NSMutableDictionary *)parameters {
    return parameters;
}

- (NSMutableURLRequest *)request:(NSMutableDictionary *)parameters url:(NSString *)url {
    return [self.manager.requestSerializer requestWithMethod:self.method
                                                   URLString:url
                                                  parameters:parameters
                                                       error:nil];
}

- (id)send:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    self.successBlock = success;
    self.failureBlock = failure;
    return [self send];
}

- (id)send {
    [self cancel];
    NSMutableDictionary* parameters = [self configure:[NSMutableDictionary dictionary]];
    if (self.parametrizer) {
        self.parametrizer(self, parameters);
    }
    NSString* url = [self.manager urlWithPath:self.path];
    NSMutableURLRequest *request = [self request:parameters url:url];
    request.timeoutInterval = self.timeout;
    WLLog(self.method, url, parameters);
    
    __strong typeof(self)strongSelf = self;
    self.operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WLAPIResponse* response = [WLAPIResponse response:responseObject];
		if (response.code == WLAPIResponseCodeSuccess) {
            WLLog(@"RESPONSE",[operation.request.URL relativeString], responseObject);
            if (strongSelf.mapper) {
                strongSelf.mapper(response, ^(id object) {
                    [strongSelf handleSuccess:object];
                }, ^(NSError *error) {
                    WLLog(@"ERROR",[operation.request.URL relativeString], error);
                    [strongSelf handleFailure:error];
                });
            } else {
                [strongSelf handleSuccess:[strongSelf objectInResponse:response]];
            }
		} else {
            WLLog(@"API ERROR",[operation.request.URL relativeString], responseObject);
            [strongSelf handleFailure:[NSError errorWithResponse:response]];
		}
        [strongSelf trackServerTime:operation.response];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WLLog(@"ERROR",[operation.request.URL relativeString], error);
        [strongSelf handleFailure:error];
    }];
    
    [self.manager.operationQueue addOperation:self.operation];
    
    return self.operation;
}

- (id)objectInResponse:(WLAPIResponse *)response {
    return response;
}

- (void)handleSuccess:(id)object {
    if (self.successBlock) {
        self.successBlock(object);
        self.successBlock = nil;
        self.failureBlock = nil;
    }
}

- (void)handleFailure:(NSError *)error {
    
    if (self.failureValidator && !self.failureValidator(self, error)) {
        return;
    }
    
    if (self.beforeFailure) {
        self.beforeFailure(error);
    }
    NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
    if (response && response.statusCode == 401 && self.reauthorizationEnabled) {
        __strong typeof(self)strongSelf = self;
        [WLSession setAuthorizationCookie:nil];
        [[WLAuthorizationRequest signIn] send:^(id object) {
            [strongSelf send];
        } failure:^(NSError *error) {
            if ([error isNetworkError]) {
                [strongSelf handleFailure:error];
            } else {
                WLAPIManagerUnauthorizedErrorBlock unauthorizedErrorBlock = [WLAPIManager manager].unauthorizedErrorBlock;
                if (unauthorizedErrorBlock) {
                    unauthorizedErrorBlock(strongSelf, error);
                } else {
                    [strongSelf handleFailure:error];
                }
            }
        }];
    } else {
        if (self.failureBlock) {
            if (error.code != NSURLErrorCancelled) {
                self.failureBlock(error);
            }
            self.failureBlock = nil;
            self.successBlock = nil;
        }
    }
    
    if (self.afterFailure) {
        self.afterFailure(error);
    }
}

- (BOOL)reauthorizationEnabled {
    return YES;
}

- (void)cancel {
    [self.operation cancel];
}

- (BOOL)loading {
    return self.operation != nil;
}

- (void)trackServerTime:(NSHTTPURLResponse*)response {
    NSDictionary* headers = [response allHeaderFields];
    NSString* serverTimeString = [headers objectForKey:@"Date"];
    if (serverTimeString) {
        static NSString *WLServerTimeFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        NSDate* serverTime = [serverTimeString GMTDateWithFormat:WLServerTimeFormat];
        if (serverTime) {
            [NSDate trackServerTime:serverTime];
        }
    }
}

@end
