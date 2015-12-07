//
//  WLAPIRequest.m
//  meWrap
//
//  Created by Ravenpod on 7/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIRequest.h"
#import "WLAuthorizationRequest.h"
#import "WLWelcomeViewController.h"

@implementation WLAPIManager

+ (instancetype)manager {
    static WLAPIManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Environment* environment = [Environment currentEnvironment];
        instance = [[self alloc] initWithBaseURL:[environment.endpoint URL]];
        instance.requestSerializer.timeoutInterval = 45;
        NSString* acceptHeader = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@", environment.version];
        [instance.requestSerializer setValue:acceptHeader forHTTPHeaderField:@"Accept"];
        [instance.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
        [instance.requestSerializer setValue:[NSBundle mainBundle].buildVersion forHTTPHeaderField:@"MEWRAP-VERSION"];
        instance.securityPolicy.allowInvalidCertificates = YES;
        instance.securityPolicy.validatesDomainName = NO;
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

+ (instancetype)requestWithMethod:(NSString*)method {
    WLAPIRequest *request = [[self alloc] init];
    request.method = method;
    return request;
}

+ (instancetype)GET {
    return [self requestWithMethod:@"GET"];
}

+ (instancetype)POST {
    return [self requestWithMethod:@"POST"];
}

+ (instancetype)PUT {
    return [self requestWithMethod:@"PUT"];
}

+ (instancetype)DELETE {
    return [self requestWithMethod:@"DELETE"];
}

- (instancetype)path:(NSString*)path, ... {
    BEGIN_ARGUMENTS(path)
    self.path = [[NSString alloc] initWithFormat:path arguments:args];
    END_ARGUMENTS
    return self;
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

- (instancetype)beforeFailure:(FailureBlock)beforeFailure {
    self.beforeFailure = beforeFailure;
    return self;
}

- (instancetype)afterFailure:(FailureBlock)afterFailure {
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
            if (file && [file isExistingFilePath]) {
                [formData appendPartWithFileURL:[file fileURL]
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

- (id)send:(ObjectBlock)success failure:(FailureBlock)failure {
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
    WLLog(@"%@ - %@: %@", self.method, url, parameters);
    
    __strong typeof(self)strongSelf = self;
    self.operation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        Response* response = [[Response alloc] initWithDictionary:responseObject];
		if (response.code == ResponseCodeSuccess) {
#ifdef DEBUG
            WLLog(@"RESPONSE - %@: %@", url, response.data);
#else
            WLLog(@"RESPONSE - %@", url);
#endif
            if (strongSelf.parser) {
                strongSelf.parser(response, ^(id object) {
                    WLLog(@"PARSED RESPONSE - %@: %@", url, object);
                    [strongSelf handleSuccess:object];
                }, ^(NSError *error) {
                    WLLog(@"ERROR - %@: %@", url, error);
                    [strongSelf handleFailure:error];
                });
            } else {
                [strongSelf handleSuccess:response];
            }
		} else {
            WLLog(@"API ERROR %ld - %@", (long)response.code, url);
            [strongSelf handleFailure:[[NSError alloc] initWithResponse:response]];
		}
        [strongSelf trackServerTime:operation.response];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        WLLog(@"ERROR - %@: %@", url, error);
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
        [[NSUserDefaults standardUserDefaults] setAuthorizationCookie:nil];
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
            self.failureBlock(error);
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
    NSString* dateStr = [headers objectForKey:@"Date"];
    if (dateStr) {
        static NSString *previousDateStr = nil;
        if (previousDateStr == nil || ![previousDateStr isEqualToString:dateStr]) {
            static NSDateFormatter *formatter = nil;
            if (!formatter) {
                formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"EEE',' dd' 'MMM' 'yyyy HH':'mm':'ss zzz"];
                [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
            }
            NSDate* serverTime = [formatter dateFromString:dateStr];
            if (serverTime) {
                [NSDate trackServerTime:serverTime];
                previousDateStr = dateStr;
            }
        }
    }
}

@end
