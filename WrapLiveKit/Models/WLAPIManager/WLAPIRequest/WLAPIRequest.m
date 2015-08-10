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
#import "AFHTTPRequestOperationManager.h"

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

@interface WLAPIManager : AFHTTPRequestOperationManager

+ (instancetype)manager;

- (NSString*)urlWithPath:(NSString*)path;

@end

@implementation WLAPIManager

+ (instancetype)manager {
    static WLAPIManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        WLAPIEnvironment* environment = [WLAPIEnvironment currentEnvironment];
        instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:environment.endpoint]];
        instance.requestSerializer.timeoutInterval = 45;
        NSString* acceptHeader = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@", environment.version];
        [instance.requestSerializer setValue:acceptHeader forHTTPHeaderField:@"Accept"];
        [instance.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        instance.securityPolicy.allowInvalidCertificates = YES;
    });
    return instance;
}

- (NSString *)urlWithPath:(NSString *)path {
    return [[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString];
}

@end

@implementation WLAPIRequest

+ (instancetype)request {
    return [[self alloc] init];
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

static WLAPIRequestUnauthorizedErrorBlock _unauthorizedErrorBlock;

+ (void)setUnauthorizedErrorBlock:(WLAPIRequestUnauthorizedErrorBlock)unauthorizedErrorBlock {
    _unauthorizedErrorBlock = unauthorizedErrorBlock;
}

- (instancetype)parse:(WLAPIRequestParser)parser {
    self.parser = parser;
    return self;
}

- (instancetype)parametrize:(WLAPIRequestParametrizer)parametrizer {
    [self.parametrizers addObject:parametrizer];
    return self;
}

- (instancetype)file:(WLAPIRequestFile)file {
    self.file = file;
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
        self.parametrizers = [NSMutableArray array];
        self.timeout = [[self class] timeout];
    }
    return self;
}

- (NSMutableDictionary *)parametrize {
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    for (WLAPIRequestParametrizer parametrizer in self.parametrizers) {
        parametrizer(self, parameters);
    }
    return parameters;
}

- (NSMutableURLRequest *)request:(NSMutableDictionary *)parameters url:(NSString *)url {
    AFHTTPRequestSerializer <AFURLRequestSerialization> *serializer = [WLAPIManager manager].requestSerializer;
    NSString* file = self.file ? self.file(self) : nil;
    if (file) {
        void (^constructing) (id<AFMultipartFormData> formData) = ^(id<AFMultipartFormData> formData) {
            if (file && [[NSFileManager defaultManager] fileExistsAtPath:file]) {
                [formData appendPartWithFileURL:[NSURL fileURLWithPath:file]
                                           name:@"qqfile"
                                       fileName:[file lastPathComponent]
                                       mimeType:@"image/jpeg" error:NULL];
            }
        };
        return [serializer multipartFormRequestWithMethod:self.method
                                                URLString:url
                                               parameters:parameters
                                constructingBodyWithBlock:constructing
                                                    error:NULL];
    } else {
        return [serializer requestWithMethod:self.method URLString:url parameters:parameters error:nil];
    }
}

- (id)send:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    self.successBlock = success;
    self.failureBlock = failure;
    return [self send];
}

- (id)send {
    [self cancel];
    if (!self.method) {
        self.method = @"GET";
    }
    WLAPIManager *manager = [WLAPIManager manager];
    NSMutableDictionary* parameters = [self parametrize];
    NSString* url = [manager urlWithPath:self.path];
    NSMutableURLRequest *request = [self request:parameters url:url];
    request.timeoutInterval = self.timeout;
    WLLog(self.method, url, parameters);
    
    __strong typeof(self)strongSelf = self;
    self.operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WLAPIResponse* response = [WLAPIResponse response:responseObject];
		if (response.code == WLAPIResponseCodeSuccess) {
            WLLog(@"RESPONSE",[operation.request.URL relativeString], responseObject);
            if (strongSelf.parser) {
                strongSelf.parser(response, ^(id object) {
                    [strongSelf handleSuccess:object];
                }, ^(NSError *error) {
                    WLLog(@"ERROR",[operation.request.URL relativeString], error);
                    [strongSelf handleFailure:error];
                });
            } else {
                [strongSelf handleSuccess:response];
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
    
    [manager.operationQueue addOperation:self.operation];
    
    return self.operation;
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
    if (response && response.statusCode == 401 && !self.skipReauthorizing) {
        __strong typeof(self)strongSelf = self;
        [WLSession setAuthorizationCookie:nil];
        [[WLAuthorizationRequest signIn] send:^(id object) {
            [strongSelf send];
        } failure:^(NSError *error) {
            if ([error isNetworkError]) {
                [strongSelf handleFailure:error];
            } else {
                if (_unauthorizedErrorBlock) {
                    _unauthorizedErrorBlock(strongSelf, error);
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
