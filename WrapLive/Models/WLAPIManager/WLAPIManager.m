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
#import "NSArray+Additions.h"
#import "WLAddressBook.h"
#import "NSDictionary+Extended.h"
#import "WLCandy.h"

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
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:user.countryCallingCode forKey:@"country_calling_code"];
	[parameters trySetObject:user.phoneNumber forKey:@"phone_number"];
	[parameters trySetObject:[WLSession password] forKey:@"password"];
	[parameters trySetObject:[user.birthdate string] forKey:@"dob"];
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
														  WLUser* user = [[WLUser alloc] initWithDictionary:[response.data objectForKey:@"user"] error:nil];
														  [WLSession setUser:user];
														  return user;
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
		[self attachFile:user.picture.large toFormData:formData];
	} success:successBlock failure:[self failureBlock:failure]];
}

- (void)contributors:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[WLAddressBook contacts:^(NSArray *contacts) {

		NSMutableArray* phoneNumbers = [NSMutableArray array];
		
		for (WLContact* contact in contacts) {
			[phoneNumbers addObjectsFromArray:contact.phoneNumbers];
		}
				
		NSDictionary* parameters = @{@"phone_numbers":phoneNumbers};
		
		id (^returnBlock) (WLAPIResponse*) = ^id(WLAPIResponse *response) {
			return [weakSelf contributorsFromResponse:response contacts:contacts];
		};
		
		[weakSelf GET:@"users/sign_up_status"
		   parameters:parameters
			  success:[weakSelf successBlock:success withObject:returnBlock failure:failure]
			  failure:[weakSelf failureBlock:failure]];
	} failure:failure];
}

- (NSArray*)contributorsFromResponse:(WLAPIResponse*)response contacts:(NSArray*)contacts {
	id signUpStatus = [response.data objectForKey:@"sign_up_status"];
	if ([signUpStatus isKindOfClass:[NSString class]]) {
		NSData* data = [signUpStatus dataUsingEncoding:NSUTF8StringEncoding];
		signUpStatus = [NSJSONSerialization JSONObjectWithData:data
															   options:NSJSONReadingAllowFragments
																 error:NULL];
		DDLogDebug(@"%@", signUpStatus);
	}
	
	NSMutableArray* contributors = [NSMutableArray array];
	
	for (NSString* phoneNumber in signUpStatus) {
		NSDictionary* value = [signUpStatus objectForKey:phoneNumber];
		if ([[value objectForKey:@"sign_up_status"] boolValue]) {
			
			WLUser* contributor = [[WLUser alloc] initWithDictionary:[value objectForKey:@"user_info"] error:NULL];
			
			if (contributor.name.length == 0) {
				WLContact* contact = [contacts selectObject:^BOOL(WLContact* item) {
					for (NSString* _phoneNumber in item.phoneNumbers) {
						if ([_phoneNumber isEqualToString:phoneNumber]) {
							return YES;
						}
					}
					return NO;
				}];
				contributor.name = contact.name;
			}
			
			[contributors addObject:contributor];
		}
	}
	
	return [contributors copy];
}

- (void)wraps:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{};
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
														  NSArray * arr = [WLWrap arrayOfModelsFromDictionaries:[response.data objectForKey:@"wraps"]];
														  return arr;
													  } failure:failure];
	[self GET:@"wraps" parameters:parameters success:successBlock failure:[self failureBlock:failure]];
}

- (void)createWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{@"name" : wrap.name};
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
														  return [[WLWrap alloc] initWithDictionary:response.data[@"wrap"] error:NULL];
													  } failure:failure];
	
	[self POST:@"wraps" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		[self attachFile:wrap.picture.large toFormData:formData];
	} success:successBlock failure:[self failureBlock:failure]];
}

- (void)updateWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	success(nil);
}

- (void)attachFile:(NSString*)path toFormData:(id <AFMultipartFormData>)formData {
	if (path) {
		[formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:@"qqfile" fileName:[path lastPathComponent] mimeType:@"image/jpeg" error:NULL];
	}
}

- (void)addCandy:(WLCandy *)candy
		  toWrap:(WLWrap *)wrap
		 success:(WLAPIManagerSuccessBlock)success
		 failure:(WLAPIManagerFailureBlock)failure {
	if ([candy.type isEqualToString:WLCandyTypeImage]) {
		
		WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
														  withObject:^id(WLAPIResponse *response) {
															  return response;
														  } failure:failure];
		NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
		[self POST:path parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
			[self attachFile:candy.picture.large toFormData:formData];
		} success:successBlock failure:[self failureBlock:failure]];
	} else {
		success(candy);
	}
}

- (void)candies:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	success(nil);
	return;
	WLAFNetworkingSuccessBlock successBlock = [self successBlock:success
													  withObject:^id(WLAPIResponse *response) {
														  return response;
													  } failure:failure];
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	[self GET:path parameters:nil success:successBlock failure:[self failureBlock:failure]];
}

@end
