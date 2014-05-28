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
#import "NSString+Additions.h"
#import "WLAuthorization.h"
#import "NSDate+Additions.h"

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

+ (BOOL)developmentEvironment {
	return [WLAPIBaseUrl isEqualToString:WLAPIDevelopmentUrl];
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

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
	return [super HTTPRequestOperationWithRequest:request success:success failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		DDLogDebug(@"%@", error);
		NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
		if (success && response && response.statusCode == 401) {
			[self signIn:[WLAuthorization currentAuthorization] success:^(id object) {
				AFHTTPRequestOperation *_operation = [operation copy];
				[_operation setCompletionBlockWithSuccess:success failure:failure];
				[self.operationQueue addOperation:_operation];
			} failure:^(NSError *error) {
				UINavigationController* navigation = (id)[UIApplication sharedApplication].keyWindow.rootViewController;
				if ([navigation isKindOfClass:[UINavigationController class]]) {
					[navigation setViewControllers:@[[navigation.storyboard welcomeViewController]] animated:YES];
				}
			}];
		} else {
			failure(operation, error);
		}
	}];
}

- (WLAFNetworkingSuccessBlock)successBlock:(WLObjectBlock)success withObject:(WLMapResponseBlock)objectBlock failure:(WLFailureBlock)failure {
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

- (WLAFNetworkingSuccessBlock)successBlock:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	return [self successBlock:success withObject:^id(WLAPIResponse *response) {
		return response;
	} failure:failure];
}

- (WLAFNetworkingFailureBlock)failureBlock:(WLFailureBlock)failure {
	return ^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure) {
			failure(error);
		}
	};
}

- (id)signUp:(WLAuthorization*)authorization
	 success:(WLAuthorizationBlock)success
	 failure:(WLFailureBlock)failure {
			
	NSDictionary* parameters = @{@"device_uid" : authorization.deviceUID,
								 @"country_calling_code" : authorization.countryCode,
								 @"phone_number" : authorization.phone,
								 @"email" : authorization.email};
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return authorization;
	};
	
	return [self POST:@"users"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)activate:(WLAuthorization*)authorization
	   success:(WLAuthorizationBlock)success
	   failure:(WLFailureBlock)failure {
	
	NSDictionary* parameters = @{@"device_uid" : authorization.deviceUID,
								 @"country_calling_code" : authorization.countryCode,
								 @"phone_number" : authorization.phone,
								 @"email" : authorization.email,
								 @"activation_code" : authorization.activationCode};
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		authorization.password = [response.data stringForKey:@"password"];
		[authorization setCurrent];
		return authorization;
	};
	
	return [self POST:@"users/activate"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)signIn:(WLAuthorization*)authorization success:(WLUserBlock)success failure:(WLFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:authorization.countryCode forKey:@"country_calling_code"];
	[parameters trySetObject:authorization.phone forKey:@"phone_number"];
	[parameters trySetObject:authorization.password forKey:@"password"];
	[parameters trySetObject:authorization.email forKey:@"email"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		WLUser* user = [WLUser modelWithDictionary:[response.data dictionaryForKey:@"user"]];
		[WLSession setUser:user];
		[authorization setCurrent];
		return user;
	};
	
	return [self POST:@"users/sign_in"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)me:(WLUserBlock)success failure:(WLFailureBlock)failure {
	NSDictionary* parameters = @{};
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		WLUser* user = [[WLUser alloc] initWithDictionary:[response.data objectForKey:@"user"] error:nil];
		[WLSession setUser:user];
		return user;
	};
	
	return [self GET:@"users/me"
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)updateMe:(WLUser *)user success:(WLUserBlock)success failure:(WLFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:user.name forKey:@"name"];
	[parameters trySetObject:user.email forKey:@"email"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		WLAuthorization* authorization = [WLAuthorization currentAuthorization];
		authorization.email = user.email;
		[authorization setCurrent];
		WLUser* user = [[WLUser alloc] initWithDictionary:response.data[@"user"] error:NULL];
		[user setCurrent];
		return user;
	};
	return [self PUT:@"users/update"
		  parameters:parameters
			filePath:user.picture.large
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)contributors:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	__weak typeof(self)weakSelf = self;
	[WLAddressBook contacts:^(NSArray *contacts) {

		if (contacts.count == 0) {
			success(nil);
			return;
		}
		
		NSMutableArray* phones = [NSMutableArray array];
		
		[contacts all:^(WLContact* contact) {
			[contact.users all:^(WLUser* user) {
				[phones addObject:user.phoneNumber];
			}];
		}];
		
		WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
			return [weakSelf contributorsFromResponse:response contacts:contacts];
		};
		
		[weakSelf POST:@"users/sign_up_status"
			parameters:@{@"phone_numbers":phones}
			   success:[weakSelf successBlock:success withObject:objectBlock failure:failure]
			   failure:[weakSelf failureBlock:failure]];
	} failure:failure];
	return nil;
}

- (NSArray*)contributorsFromResponse:(WLAPIResponse*)response contacts:(NSArray*)contacts {
	NSArray* users = response.data[@"users"];
	[contacts all:^(WLContact* contact) {
		[contact.users all:^(WLUser* user) {
			for (NSDictionary* userData in users) {
				if ([userData[@"address_book_number"] isEqualToString:user.phoneNumber]) {
					NSString* name = user.name;
					NSString* label = user.phoneNumber.label;
					[user updateWithDictionary:userData];
					if (user.name.nonempty) {
						contact.name = user.name;
					} else {
						user.name = name;
					}
					user.phoneNumber.label = label;
				}
			}
		}];
	}];
	return contacts;
}

- (id)wraps:(NSInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure {

	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(page) forKey:@"page"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		NSArray* wraps = [WLWrap arrayOfModelsFromDictionaries:[response.data arrayForKey:@"wraps"]];
		if (page == 1 && wraps.nonempty) {
			NSArray* candies = [response.data arrayForKey:@"recent_candies"];
			if (candies.nonempty) {
				candies = [WLCandy arrayOfModelsFromDictionaries:candies];
				WLWrap* wrap = [wraps firstObject];
				wrap.dates = (id)[WLWrapDate datesWithCandies:candies];
			}
		}
		return wraps;
	};
	
	return [self GET:@"wraps"
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)wrap:(WLWrap *)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [self wrap:wrap page:1 success:success failure:failure];
}

- (id)wrap:(WLWrap *)wrap page:(NSInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@([[NSTimeZone localTimeZone] secondsFromGMT]) forKey:@"utc_offset"];
	[parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
	[parameters trySetObject:@(page) forKey:@"group_by_date_page_number"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [wrap updateWithDictionary:response.data[@"wrap"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (NSDictionary*)parametersForWrap:(WLWrap*)wrap {
	NSMutableArray* contributors = [NSMutableArray array];
	NSMutableArray* invitees = [NSMutableArray array];
	for (WLUser* contributor in wrap.contributors) {
		if (contributor.identifier.nonempty) {
			[contributors addObject:contributor.identifier];
		} else {
			NSData* invitee = [NSJSONSerialization dataWithJSONObject:@{@"name":WLString(contributor.name),@"phone_number":contributor.phoneNumber} options:0 error:NULL];
			[invitees addObject:[[NSString alloc] initWithData:invitee encoding:NSUTF8StringEncoding]];
		}
	}
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:wrap.name forKey:@"name"];
	[parameters trySetObject:contributors forKey:@"user_uids"];
	[parameters trySetObject:invitees forKey:@"invitees"];
	return parameters;
}

- (id)createWrap:(WLWrap *)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		WLWrap* _wrap = [wrap updateWithDictionary:response.data[@"wrap"]];
		[_wrap broadcastCreation];
		return _wrap;
	};
	return [self POST:@"wraps"
		   parameters:[self parametersForWrap:wrap]
			 filePath:wrap.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)updateWrap:(WLWrap *)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [wrap updateWithDictionary:response.data[@"wrap"]];
	};
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	return [self PUT:path
		   parameters:[self parametersForWrap:wrap]
			 filePath:wrap.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)leaveWrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	wrap = [wrap copy];
	wrap.contributors = (id)[wrap.contributors usersByRemovingCurrentUser];
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		[wrap broadcastRemoving];
		return response;
	};
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	return [self PUT:path
		  parameters:[self parametersForWrap:wrap]
			filePath:wrap.picture.large
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)removeWrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		[wrap broadcastRemoving];
		return response;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	return [self DELETE:path
			 parameters:nil
				success:[self successBlock:success withObject:objectBlock failure:failure]
				failure:[self failureBlock:failure]];
}

- (void)attachFile:(NSString*)path toFormData:(id <AFMultipartFormData>)formData {
	if (path && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[formData appendPartWithFileURL:[NSURL fileURLWithPath:path] name:@"qqfile" fileName:[path lastPathComponent] mimeType:@"image/jpeg" error:NULL];
	}
}

- (id)addCandy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:candy.uploadIdentifier forKey:@"upload_uid"];
	[parameters trySetObject:@(candy.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
	if (candy.type == WLCandyTypeChatMessage) {
		[parameters trySetObject:candy.chatMessage forKey:@"chat_message"];
	}
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		[candy updateWithDictionary:[response.data dictionaryForKey:@"candy"] broadcast:NO];
		return candy;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
	
	return [self POST:path
		   parameters:parameters
			 filePath:(candy.type == WLCandyTypeImage ? candy.picture.large : nil)
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)candies:(WLWrap *)wrap date:(WLWrapDate *)date success:(WLArrayBlock)success failure:(WLFailureBlock)failure {

	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(date.updatedAt.timestamp) forKey:@"start_date_in_epoch"];
	[parameters trySetObject:@(floorf([date.candies count] / 10) + 1) forKey:@"candy_page_number"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [WLCandy arrayOfModelsFromDictionaries:response.data[@"candies"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)removeCandy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		[wrap removeCandy:candy];
		return response;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@", wrap.identifier, candy.identifier];
	return [self DELETE:path
			 parameters:nil
				success:[self successBlock:success withObject:objectBlock failure:failure]
				failure:[self failureBlock:failure]];
}

- (id)messages:(WLWrap *)wrap page:(NSUInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(page) forKey:@"page"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [WLCandy arrayOfModelsFromDictionaries:response.data[@"chat_messages"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/chat_messages", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)candy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [candy updateWithDictionary:[response.data dictionaryForKey:@"candy"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@", wrap.identifier, candy.identifier];

	return [self GET:path
		  parameters:nil
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)addComment:(WLComment*)comment
		   candy:(WLCandy *)candy
		  wrap:(WLWrap *)wrap
		   success:(WLCommentBlock)success
		   failure:(WLFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:comment.text forKey:@"message"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		WLComment* comment = [[WLComment alloc] initWithDictionary:[response.data dictionaryForKey:@"comment"] error:NULL];
		[candy addComment:comment];
		return comment;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@/comments", wrap.identifier, candy.identifier];
	
	return [self POST:path
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
	
}

- (id)removeComment:(WLComment *)comment candy:(WLCandy *)candy wrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		[candy removeComment:comment];
		return response;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@/comments/%@", wrap.identifier, candy.identifier, comment.identifier];
	return [self DELETE:path
			 parameters:nil
				success:[self successBlock:success withObject:objectBlock failure:failure]
				failure:[self failureBlock:failure]];
}

- (id)uploadStatus:(NSArray *)identifiers success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:identifiers forKey:@"upload_uids"];
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [response.data arrayForKey:@"upload_status"];
	};
	return [self POST:@"candies/upload_status"
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

@end

@implementation WLWrap (WLAPIManager)

- (id)create:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] createWrap:self success:success failure:failure];
}

- (id)update:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] updateWrap:self success:success failure:failure];
}

- (id)fetch:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] wrap:self success:success failure:failure];
}

- (id)fetch:(NSInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] wrap:self page:page success:success failure:failure];
}

- (id)addCandy:(WLCandy *)candy success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] addCandy:candy wrap:self success:success failure:failure];
}

- (id)candies:(WLWrapDate *)date success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] candies:self date:date success:success failure:failure];
}

- (id)messages:(NSUInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] messages:self page:page success:success failure:failure];
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] removeWrap:self success:success failure:failure];
}

- (id)leave:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] leaveWrap:self success:success failure:failure];
}

- (id)removeCandy:(WLCandy *)candy success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] removeCandy:candy wrap:self success:success failure:failure];
}

@end

@implementation WLCandy (WLAPIManager)

- (id)addComment:(WLComment *)comment wrap:(WLWrap *)wrap success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] addComment:comment candy:self wrap:wrap success:success failure:failure];
}

- (id)removeComment:(WLComment*)comment wrap:(WLWrap*)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] removeComment:comment candy:self wrap:wrap success:success failure:failure];
}

- (id)remove:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] removeCandy:self wrap:wrap success:success failure:failure];
}

- (id)fetch:(WLWrap *)wrap success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] candy:self wrap:wrap success:success failure:failure];
}

@end

@implementation WLAuthorization (WLAPIManager)

- (id)signUp:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] signUp:self success:success failure:failure];
}

- (id)activate:(WLAuthorizationBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] activate:self success:success failure:failure];
}

- (id)signIn:(WLUserBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] signIn:self success:success failure:failure];
}

@end
