//
//  WLAPIManager.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAPIManager.h"
#import "WLWrap.h"
#import "WLUser.h"
#import "WLSession.h"
#import "NSDate+Formatting.h"
#import "WLAPIResponse.h"
#import <CocoaLumberjack/DDLog.h>

static const int ddLogLevel = LOG_LEVEL_DEBUG;

static NSString* WLAPIStageUrl = @"https://dev-api.wraplive.com/api";
static NSString* WLAPIProductionUrl = @"";
#define WLAPIBaseUrl WLAPIStageUrl

typedef void (^WLAFNetworkingSuccessBlock) (AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WLAFNetworkingFailureBlock) (AFHTTPRequestOperation *operation, NSError *error);

@implementation WLAPIManager

+ (instancetype)instance {
    static WLAPIManager* instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:WLAPIBaseUrl]];
		instance.requestSerializer.timeoutInterval = 30;
		[instance.requestSerializer setValue:@"application/vnd.ravenpod+json;version=1" forHTTPHeaderField:@"Accept"];
	});
    return instance;
}

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
					 parameters:(NSDictionary *)parameters
						success:(void (^)(AFHTTPRequestOperation *, id))success
						failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	DDLogDebug(@"%@: %@",URLString, parameters);
	return [super GET:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
					  parameters:(NSDictionary *)parameters
	   constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block
						 success:(void (^)(AFHTTPRequestOperation *, id))success
						 failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	DDLogDebug(@"%@: %@",URLString, parameters);
	return [super POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	DDLogDebug(@"%@: %@",URLString, parameters);
	return [super POST:URLString parameters:parameters success:success failure:failure];
}

- (WLAFNetworkingSuccessBlock)successBlock:(WLAPIManagerSuccessBlock)success withObject:(id (^)(WLAPIResponse* response))objectBlock failure:(WLAPIManagerFailureBlock)failure {
	return ^(AFHTTPRequestOperation *operation, id responseObject) {
		DDLogDebug(@"%@", responseObject);
		WLAPIResponse* response = [[WLAPIResponse alloc] initWithDictionary:responseObject error:NULL];
		if (response.code == WLAPIResponseCodeSuccess) {
			success(objectBlock(response));
		} else {
			failure([NSError errorWithDescription:response.message]);
		}
	};
}

- (WLAFNetworkingFailureBlock)failureBlock:(WLAPIManagerFailureBlock)failure {
	return ^(AFHTTPRequestOperation *operation, NSError *error) {
		DDLogDebug(@"%@", error);
		failure(error);
	};
}

- (id)signUp:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{@"device_uid" : [WLSession UDID],
								 @"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"dob" : [user.birthdate string]};
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
																   return user;
															   } failure:failure];
	return [self POST:@"users" parameters:parameters success:successBlock failure:[self failureBlock:failure]];
}

- (id)activate:(WLUser *)user code:(NSString *)code success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{@"device_uid" : [WLSession UDID],
								 @"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"activation_code" : code,
								 @"dob" : [user.birthdate string]};
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
														  NSString* password = [response.data objectForKey:@"password"];
														  [WLSession setPassword:password];
														  return password;
													  } failure:failure];
	return [self POST:@"users/activate" parameters:parameters success:successBlock failure:[self failureBlock:failure]];
}

- (id)signIn:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{@"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"password" : [WLSession password],
								 @"dob" : [user.birthdate string]};
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
														  return response;
													  } failure:failure];
	return [self POST:@"users/sign_in" parameters:parameters success:successBlock failure:[self failureBlock:failure]];
}

- (void)me:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{};
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
														  return response;
													  } failure:failure];
	[self GET:@"users/me" parameters:parameters success:successBlock failure:[self failureBlock:failure]];
}

- (void)updateMe:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{@"name":user.name};
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
														  return response;
													  } failure:failure];
	[self POST:@"users/update" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		[formData appendPartWithFileURL:[NSURL fileURLWithPath:user.avatar] name:@"qqfile" error:NULL];
	} success:successBlock failure:[self failureBlock:failure]];
}

- (void)wraps:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSArray* wraps = [WLWrap arrayOfModelsFromDictionaries:[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WLDummyWraps" ofType:@"plist"]]];
	success(wraps);
}

@end
