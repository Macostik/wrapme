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

@implementation WLAPIRequest

- (void)dealloc {
    NSLog(@"%@ dealloc", NSStringFromClass([self class]));
}

+ (instancetype)request {
    return [[self alloc] init];
}

+ (NSString *)defaultMethod {
    return @"GET";
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.method = [[self class] defaultMethod];
    }
    return self;
}

- (WLAPIManager *)manager {
    return [WLAPIManager instance];
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
    WLLog(self.method, url, parameters);
    
    __strong typeof(self)strongSelf = self;
    self.operation = [self.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        WLAPIResponse* response = [WLAPIResponse response:responseObject];
		if (response.code == WLAPIResponseCodeSuccess) {
            WLLog(@"RESPONSE",[operation.request.URL relativeString], responseObject);
            [strongSelf handleSuccess:[strongSelf objectInResponse:response]];
		} else {
            WLLog(@"API ERROR",[operation.request.URL relativeString], responseObject);
            [strongSelf handleFailure:[NSError errorWithDescription:response.message code:response.code]];
		}
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
    [[WLEntryManager manager] save];
    if (self.successBlock) {
        self.successBlock(object);
        self.successBlock = nil;
        self.failureBlock = nil;
    }
}

- (void)handleFailure:(NSError *)error {
    NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
    if (response && response.statusCode == 401) {
        __strong typeof(self)strongSelf = self;
        [[WLAuthorizationRequest signInRequest] send:^(id object) {
            [strongSelf send];
        } failure:^(NSError *error) {
            [WLWelcomeViewController instantiateAndMakeRootViewControllerAnimated:NO];
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

- (void)cancel {
    [self.operation cancel];
}

@end
