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
#import "WLCandy.h"
#import "WLComment.h"

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
		instance.requestSerializer.timeoutInterval = 45;
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

- (AFHTTPRequestOperation *)POST:(NSString *)URLString parameters:(NSDictionary *)parameters filePath:(NSString*)filePath success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	
	void (^constructingBlock) (id<AFMultipartFormData>) = ^(id<AFMultipartFormData> formData) {
		[self attachFile:filePath toFormData:formData];
	};
	
	AFHTTPRequestOperation* operation = [self POST:URLString
										parameters:parameters
						 constructingBodyWithBlock:constructingBlock
										   success:success
										   failure:failure];
	
	return operation;
}

- (WLAFNetworkingSuccessBlock)successBlock:(WLAPIManagerSuccessBlock)success withObject:(WLAPIManagerObjectBlock)objectBlock failure:(WLAPIManagerFailureBlock)failure {
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

- (id)signUp:(WLUser *)user
	 success:(WLAPIManagerSuccessBlock)success
	 failure:(WLAPIManagerFailureBlock)failure {
	
	NSDictionary* parameters = @{@"device_uid" : [WLSession UDID],
								 @"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"dob" : [user.birthdate string]};
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return user;
	};
	
	return [self POST:@"users"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)activate:(WLUser *)user
		  code:(NSString *)code
	   success:(WLAPIManagerSuccessBlock)success
	   failure:(WLAPIManagerFailureBlock)failure {
	
	NSDictionary* parameters = @{@"device_uid" : [WLSession UDID],
								 @"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"activation_code" : code,
								 @"dob" : [user.birthdate string]};
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		NSString* password = [response.data objectForKey:@"password"];
		[WLSession setPassword:password];
		return password;
	};
	
	return [self POST:@"users/activate"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)signIn:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:user.countryCallingCode forKey:@"country_calling_code"];
	[parameters trySetObject:user.phoneNumber forKey:@"phone_number"];
	[parameters trySetObject:[WLSession password] forKey:@"password"];
	[parameters trySetObject:[user.birthdate string] forKey:@"dob"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return response;
	};
	
	return [self POST:@"users/sign_in"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)me:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	NSDictionary* parameters = @{};
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		WLUser* user = [[WLUser alloc] initWithDictionary:[response.data objectForKey:@"user"] error:nil];
		[WLSession setUser:user];
		return user;
	};
	
	return [self GET:@"users/me"
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)updateMe:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:user.name forKey:@"name"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		WLUser* user = [[WLUser alloc] initWithDictionary:response.data[@"user"] error:NULL];
		[user setCurrent];
		return user;
	};
	
	return [self POST:@"users/update"
		   parameters:parameters
			 filePath:user.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)contributors:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[WLAddressBook contacts:^(NSArray *contacts) {

		NSMutableArray* phoneNumbers = [NSMutableArray array];
		
		for (WLContact* contact in contacts) {
			[phoneNumbers addObjectsFromArray:contact.phoneNumbers];
		}
				
		NSDictionary* parameters = @{@"phone_numbers":phoneNumbers};
		
		WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
			return [weakSelf contributorsFromResponse:response contacts:contacts];
		};
		
		[weakSelf GET:@"users/sign_up_status"
		   parameters:parameters
			  success:[weakSelf successBlock:success withObject:objectBlock failure:failure]
			  failure:[weakSelf failureBlock:failure]];
	} failure:failure];
	return nil;
}

- (NSArray*)contributorsFromResponse:(WLAPIResponse*)response contacts:(NSArray*)contacts {
	
	return [[response.data arrayForKey:@"users"] map:^id(NSDictionary* userInfo) {
		
		WLUser* contributor = [[WLUser alloc] initWithDictionary:userInfo error:NULL];
		
		if (contributor.name.length == 0) {
			NSString* phoneNumber = [userInfo objectForKey:@"address_book_number"];
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
		return contributor;
	}];
}

- (id)wrapsWithPage:(NSInteger)page success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {

	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(page) forKey:@"page"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [WLWrap arrayOfModelsFromDictionaries:[response.data arrayForKey:@"wraps"]];
	};
	
	return [self GET:@"wraps"
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)homeWraps:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		NSArray* wraps = [WLWrap arrayOfModelsFromDictionaries:[response.data arrayForKey:@"wraps"]];
		WLWrap* topWrap = [wraps firstObject];
		topWrap.candies = [WLCandy arrayOfModelsFromDictionaries:[response.data arrayForKey:@"latest_candies"]];
		return wraps;
	};
	
	return [self GET:@"wraps/home"
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)createWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSArray* contributors = [wrap.contributors map:^id(WLUser* contributor) {
		return contributor.identifier;
	}];
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:wrap.name forKey:@"name"];
	[parameters trySetObject:contributors forKey:@"user_uids"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [[WLWrap alloc] initWithDictionary:response.data[@"wrap"] error:NULL];
	};
	
	return [self POST:@"wraps"
		   parameters:parameters
			 filePath:wrap.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)updateWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	success(nil);
	return nil;
}

- (void)attachFile:(NSString*)path toFormData:(id <AFMultipartFormData>)formData {
	if (path) {
		[formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:@"qqfile" fileName:[path lastPathComponent] mimeType:@"image/jpeg" error:NULL];
	}
}

- (id)addCandy:(WLCandy *)candy
		  toWrap:(WLWrap *)wrap
		 success:(WLAPIManagerSuccessBlock)success
		 failure:(WLAPIManagerFailureBlock)failure {
	if (candy.type == WLCandyTypeImage) {
		
		WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
			WLCandy* candy = [[WLCandy alloc] initWithDictionary:[response.data dictionaryForKey:@"candy"] error:NULL];
			candy.type = WLCandyTypeImage;
			[wrap addCandy:candy];
			return candy;
		};
		
		NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
		
		return [self POST:path
			   parameters:nil
				 filePath:candy.picture.large
				  success:[self successBlock:success withObject:objectBlock failure:failure]
				  failure:[self failureBlock:failure]];
	} else {
		success(candy);
		return nil;
	}
}

- (id)candies:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	success(nil);
	return nil;
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return response;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	
	return [self GET:path
		  parameters:nil
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)candyInfo:(WLCandy *)candy forWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [[WLCandy alloc] initWithDictionary:[response.data dictionaryForKey:@"candy"] error:NULL];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@", wrap.identifier, candy.identifier];

	return [self GET:path
		  parameters:nil
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)addComment:(WLComment*)comment
		   toCandy:(WLCandy *)candy
		  fromWrap:(WLWrap *)wrap
		   success:(WLAPIManagerSuccessBlock)success
		   failure:(WLAPIManagerFailureBlock)failure {
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		WLComment* comment = [[WLComment alloc] initWithDictionary:[response.data dictionaryForKey:@"comment"] error:NULL];
		[candy addComment:comment];
		return comment;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@/comments", wrap.identifier, candy.identifier];
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:comment.text forKey:@"message"];
	
	return [self POST:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

@end
