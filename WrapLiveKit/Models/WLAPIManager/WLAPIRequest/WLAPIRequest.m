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
#import "WLNavigation.h"
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
    NSString* url = [self.manager urlWithPath:self.path];
    NSMutableURLRequest *request = [self request:parameters url:url];
    request.timeoutInterval = self.timeout;
    WLLog(self.method, url, parameters);
    
    __strong typeof(self)strongSelf = self;
    self.operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WLAPIResponse* response = [WLAPIResponse response:responseObject];
		if (response.code == WLAPIResponseCodeSuccess) {
            WLLog(@"RESPONSE",[operation.request.URL relativeString], responseObject);
            [strongSelf handleSuccess:[strongSelf objectInResponse:response]];
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
    NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
    if (response && response.statusCode == 401 && self.reauthorizationEnabled) {
        __strong typeof(self)strongSelf = self;
        [[WLAuthorizationRequest signInRequest] send:^(id object) {
            [strongSelf send];
        } failure:^(NSError *error) {
            WLFailureBlock unauthorizedErrorBlock = [WLAPIManager manager].unauthorizedErrorBlock;
            if (unauthorizedErrorBlock) {
                unauthorizedErrorBlock(error);
            } else {
                [strongSelf handleFailure:error];
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
