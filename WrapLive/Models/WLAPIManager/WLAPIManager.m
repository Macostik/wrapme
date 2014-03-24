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

static NSString* WLAPIStageUrl = @"https://dev-api.wraplive.com";
static NSString* WLAPIProductionUrl = @"";
#define WLAPIBaseUrl WLAPIStageUrl

@implementation WLAPIManager

+ (instancetype)instance {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:WLAPIBaseUrl]];
	});
    return instance;
}

- (void)signUp:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{@"device_uid" : [WLSession UDID],
								 @"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"name" : user.name};
	NSLog(@"%@", parameters);
	[self POST:@"users" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		success(user);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		failure(error);
	}];
}

- (void)activate:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{};
	[self POST:@"users/activate" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		success(responseObject);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		failure(error);
	}];
}

- (void)signIn:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{};
	[self POST:@"users/sign_in" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		success(responseObject);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		failure(error);
	}];
}

- (void)me:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{};
	[self GET:@"users/me" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
		success(responseObject);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		failure(error);
	}];
}

- (void)updateMe:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSDictionary* parameters = @{};
	[self POST:@"users/update" parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
		[formData appendPartWithFileURL:[NSURL fileURLWithPath:user.avatar] name:@"qqfile" error:NULL];
	} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		success(responseObject);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		failure(error);
	}];
}

- (void)wraps:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSArray* wraps = [WLWrap arrayOfModelsFromDictionaries:[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WLDummyWraps" ofType:@"plist"]]];
	success(wraps);
}

@end
