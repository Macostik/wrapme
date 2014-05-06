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
#import "WLWrapDate.h"
#import "UIStoryboard+Additions.h"
#import "WLWrapBroadcaster.h"

static const int ddLogLevel = LOG_LEVEL_DEBUG;

static NSString* WLAPIDevelopmentUrl = @"https://dev-api.wraplive.com/api";
static NSString* WLAPIQAUrl = @"https://qa-api.wraplive.com/api";
static NSString* WLAPIProductionUrl = @"https://api.wraplive.com/api";
#define WLAPIBaseUrl WLAPIDevelopmentUrl

typedef void (^WLAFNetworkingSuccessBlock) (AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WLAFNetworkingFailureBlock) (AFHTTPRequestOperation *operation, NSError *error);

@implementation WLAPIManager

+ (instancetype)instance {
    static WLAPIManager* instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString* baseUrl = WLAPIBaseUrl;
		DDLogDebug(@"WebService Environment: %@", baseUrl);
		instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
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

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	DDLogDebug(@"%@: %@",URLString, parameters);
	return [super PUT:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString parameters:(NSDictionary *)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	DDLogDebug(@"%@: %@",URLString, parameters);
	NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:@"PUT" URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];
	AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request success:success failure:failure];
	[self.operationQueue addOperation:operation];
	return operation;
}

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString parameters:(NSDictionary *)parameters filePath:(NSString*)filePath success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	
	void (^constructingBlock) (id<AFMultipartFormData>) = ^(id<AFMultipartFormData> formData) {
		[self attachFile:filePath toFormData:formData];
	};
	
	AFHTTPRequestOperation* operation = [self PUT:URLString
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

- (WLAFNetworkingSuccessBlock)successBlock:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	return [self successBlock:success withObject:^id(WLAPIResponse *response) {
		return response;
	} failure:failure];
}

- (WLAFNetworkingFailureBlock)failureBlock:(WLAPIManagerFailureBlock)failure success:(WLAPIManagerSuccessBlock)success {
	return ^(AFHTTPRequestOperation *operation, NSError *error) {
		DDLogDebug(@"%@", error);
		NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
		if (response && response.statusCode == 401) {
			[self signIn:[WLSession user] success:^(id object) {
				[self.operationQueue addOperation:[operation copy]];
			} failure:^(NSError *error) {
				UINavigationController* navigation = (id)[UIApplication sharedApplication].keyWindow.rootViewController;
				if ([navigation isKindOfClass:[UINavigationController class]]) {
					[navigation setViewControllers:@[[navigation.storyboard welcomeViewController]] animated:YES];
				}
			}];
		} else {
			failure(error);
		}
	};
}

- (id)signUp:(WLUser *)user
	 success:(WLAPIManagerSuccessBlock)success
	 failure:(WLAPIManagerFailureBlock)failure {
	
	NSString* birthdate = [user.birthdate GMTString];
	
	[WLSession setBirthdate:birthdate];
	
	NSDictionary* parameters = @{@"device_uid" : [WLSession UDID],
								 @"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"dob" : birthdate};
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return user;
	};
	
	return [self POST:@"users"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure success:success]];
}

- (id)activate:(WLUser *)user
		  code:(NSString *)code
	   success:(WLAPIManagerSuccessBlock)success
	   failure:(WLAPIManagerFailureBlock)failure {
	
	NSDictionary* parameters = @{@"device_uid" : [WLSession UDID],
								 @"country_calling_code" : user.countryCallingCode,
								 @"phone_number" : user.phoneNumber,
								 @"activation_code" : code,
								 @"dob" : [WLSession birthdate]};
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		NSString* password = [response.data stringForKey:@"password"];
		[WLSession setPassword:password];
		return password;
	};
	
	return [self POST:@"users/activate"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure success:success]];
}

- (id)signIn:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:user.countryCallingCode forKey:@"country_calling_code"];
	[parameters trySetObject:user.phoneNumber forKey:@"phone_number"];
	[parameters trySetObject:[WLSession password] forKey:@"password"];
	[parameters trySetObject:[WLSession birthdate] forKey:@"dob"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		[user updateWithDictionary:[response.data dictionaryForKey:@"user"]];
		[WLSession setUser:user];
		return user;
	};
	
	return [self POST:@"users/sign_in"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure success:success]];
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
			 failure:[self failureBlock:failure success:success]];
}

- (id)updateMe:(WLUser *)user success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:user.name forKey:@"name"];
	
	NSString* birthdate = [user.birthdate GMTString];
	[parameters trySetObject:birthdate forKey:@"dob"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		[WLSession setBirthdate:birthdate];
		WLUser* user = [[WLUser alloc] initWithDictionary:response.data[@"user"] error:NULL];
		[user setCurrent];
		return user;
	};
	return [self PUT:@"users/update"
		  parameters:parameters
			filePath:user.picture.large
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure success:success]];
}

- (id)contributors:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[WLAddressBook contacts:^(NSArray *contacts) {

		NSMutableArray* phoneNumbers = [NSMutableArray array];
		
		for (WLContact* contact in contacts) {
			[phoneNumbers addObjectsFromArray:contact.phoneNumbers];
		}
		if (phoneNumbers.count == 0) {
			success(nil);
			return;
		}
		NSDictionary* parameters = @{@"phone_numbers":phoneNumbers};
		
		WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
			return [weakSelf contributorsFromResponse:response contacts:contacts];
		};
		
		[weakSelf POST:@"users/sign_up_status"
			parameters:parameters
			   success:[weakSelf successBlock:success withObject:objectBlock failure:failure]
			   failure:[weakSelf failureBlock:failure success:success]];
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

- (id)wraps:(NSInteger)page success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {

	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(page) forKey:@"page"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [WLWrap arrayOfModelsFromDictionaries:[response.data arrayForKey:@"wraps"]];
	};
	
	AFHTTPRequestOperation* operation = [self GET:@"wraps"
									   parameters:parameters
										  success:[self successBlock:success withObject:objectBlock failure:failure]
										  failure:[self failureBlock:failure success:success]];
	[operation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
		return cachedResponse;
	}];
	return operation;
}

- (id)wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	return [self wrap:wrap page:1 success:success failure:failure];
}

- (id)wrap:(WLWrap *)wrap page:(NSInteger)page success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@([[NSTimeZone localTimeZone] secondsFromGMT]) forKey:@"utc_offset"];
	[parameters trySetObject:@(page) forKey:@"group_by_date_page_number"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [wrap updateWithDictionary:response.data[@"wrap"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure success:success]];
}

- (id)createWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSArray* contributors = [wrap.contributors map:^id(WLUser* contributor) {
		return contributor.identifier;
	}];
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:wrap.name forKey:@"name"];
	[parameters trySetObject:contributors forKey:@"user_uids"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		WLWrap* _wrap = [wrap updateWithDictionary:response.data[@"wrap"]];
		[_wrap broadcastCreation];
		return _wrap;
	};
	
	return [self POST:@"wraps"
		   parameters:parameters
			 filePath:wrap.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure success:success]];
}

- (id)updateWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSArray* contributors = [wrap.contributors map:^id(WLUser* contributor) {
		return contributor.identifier;
	}];
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:wrap.name forKey:@"name"];
	[parameters trySetObject:contributors forKey:@"user_uids"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [wrap updateWithDictionary:response.data[@"wrap"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	return [self PUT:path
		   parameters:parameters
			 filePath:wrap.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure success:success]];
}

- (id)removeWrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	return [self DELETE:path
			 parameters:nil
				success:[self successBlock:success failure:failure]
				failure:[self failureBlock:failure success:success]];
}

- (void)attachFile:(NSString*)path toFormData:(id <AFMultipartFormData>)formData {
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:@"qqfile" fileName:[path lastPathComponent] mimeType:@"image/jpeg" error:NULL];
	}
}

- (id)addCandy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	if (candy.type == WLCandyTypeChatMessage) {
		[parameters trySetObject:candy.chatMessage forKey:@"chat_message"];
	}
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		[candy updateWithDictionary:[response.data dictionaryForKey:@"candy"]];
		return candy;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
	
	return [self POST:path
		   parameters:parameters
			 filePath:(candy.type == WLCandyTypeImage ? candy.picture.large : nil)
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure success:success]];
}

- (id)candies:(WLWrap *)wrap date:(WLWrapDate *)date success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {

	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@([date.updatedAt timeIntervalSince1970]) forKey:@"start_date_in_epoch"];
	[parameters trySetObject:@(floorf([date.candies count] / 10) + 1) forKey:@"candy_page_number"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [WLCandy arrayOfModelsFromDictionaries:response.data[@"candies"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure success:success]];
}

- (id)removeCandy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@", wrap.identifier, candy.identifier];
	return [self DELETE:path
			 parameters:nil
				success:[self successBlock:success failure:failure]
				failure:[self failureBlock:failure success:success]];
}

- (id)messages:(WLWrap *)wrap page:(NSUInteger)page success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(page) forKey:@"page"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [WLCandy arrayOfModelsFromDictionaries:response.data[@"chat_messages"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/chat_messages", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure success:success]];
}

- (id)candy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		return [candy updateWithDictionary:[response.data dictionaryForKey:@"candy"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@", wrap.identifier, candy.identifier];

	return [self GET:path
		  parameters:nil
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure success:success]];
}

- (id)addComment:(WLComment*)comment
		   candy:(WLCandy *)candy
		  wrap:(WLWrap *)wrap
		   success:(WLAPIManagerSuccessBlock)success
		   failure:(WLAPIManagerFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:comment.text forKey:@"message"];
	
	WLAPIManagerObjectBlock objectBlock = ^id(WLAPIResponse *response) {
		WLComment* comment = [[WLComment alloc] initWithDictionary:[response.data dictionaryForKey:@"comment"] error:NULL];
		[candy addComment:comment];
		return comment;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@/comments", wrap.identifier, candy.identifier];
	
	return [self POST:path
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure success:success]];
	
}

- (id)removeComment:(WLComment *)comment candy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLAPIManagerSuccessBlock)success failure:(WLAPIManagerFailureBlock)failure {
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@/comments/%@", wrap.identifier, candy.identifier, comment.identifier];
	return [self DELETE:path
			 parameters:nil
				success:[self successBlock:success failure:failure]
				failure:[self failureBlock:failure success:success]];
}

@end
