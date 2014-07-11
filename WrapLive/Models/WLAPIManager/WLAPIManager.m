//
//  WLAPIManager.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAPIManager.h"
#import "WLSession.h"
#import "NSDate+Formatting.h"
#import "WLAPIResponse.h"
#import "NSArray+Additions.h"
#import "WLAddressBook.h"
#import "WLNavigation.h"
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"
#import "WLAuthorization.h"
#import "NSDate+Additions.h"
#import "WLWelcomeViewController.h"
#import "WLImageCache.h"

static NSString* WLAPILocalUrl = @"http://192.168.33.10:3000/api";
static NSString* WLAPIDevelopmentUrl = @"https://dev-api.wraplive.com/api";
static NSString* WLAPIQAUrl = @"https://qa-api.wraplive.com/api";
static NSString* WLAPIProductionUrl = @"https://api.wraplive.com/api";
#define WLAPIBaseUrl WLAPIQAUrl

static NSString* WLAPIVersion = @"2";

#define WLAcceptHeader [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@", WLAPIVersion]

typedef void (^WLAFNetworkingSuccessBlock) (AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WLAFNetworkingFailureBlock) (AFHTTPRequestOperation *operation, NSError *error);

@implementation WLAPIManager

+ (instancetype)instance {
    static WLAPIManager* instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString* baseUrl = WLAPIBaseUrl;
        WLLog(baseUrl,@"API environment initialized", nil);
		instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:baseUrl]];
		instance.requestSerializer.timeoutInterval = 45;
		[instance.requestSerializer setValue:WLAcceptHeader forHTTPHeaderField:@"Accept"];
	});
    return instance;
}

+ (BOOL)developmentEvironment {
	return [WLAPIBaseUrl isEqualToString:WLAPIDevelopmentUrl];
}

static BOOL signedIn = NO;

+ (BOOL)signedIn {
    return signedIn;
}

- (AFHTTPRequestOperation *)GET:(NSString *)URLString
					 parameters:(NSDictionary *)parameters
						success:(void (^)(AFHTTPRequestOperation *, id))success
						failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    WLLog(@"GET",URLString, parameters);
	return [super GET:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString
					  parameters:(NSDictionary *)parameters
	   constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block
						 success:(void (^)(AFHTTPRequestOperation *, id))success
						 failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    WLLog(@"POST",URLString, parameters);
	return [super POST:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

- (AFHTTPRequestOperation *)POST:(NSString *)URLString parameters:(NSDictionary *)parameters success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    WLLog(@"POST",URLString, parameters);
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
    WLLog(@"PUT",URLString, parameters);
	return [super PUT:URLString parameters:parameters success:success failure:failure];
}

- (AFHTTPRequestOperation *)PUT:(NSString *)URLString parameters:(NSDictionary *)parameters constructingBodyWithBlock:(void (^)(id<AFMultipartFormData>))block success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    WLLog(@"PUT",URLString, parameters);
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
        WLLog(@"ERROR",[operation.request.URL relativeString], error);
		NSHTTPURLResponse* response = [error.userInfo objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
		if (success && response && response.statusCode == 401) {
			[self signIn:[WLAuthorization currentAuthorization] success:^(id object) {
				AFHTTPRequestOperation *_operation = [operation copy];
				[_operation setCompletionBlockWithSuccess:success failure:failure];
				[self.operationQueue addOperation:_operation];
			} failure:^(NSError *error) {
				[WLWelcomeViewController instantiateAndMakeRootViewControllerAnimated:NO];
			}];
		} else {
			failure(operation, error);
		}
	}];
}

- (WLAFNetworkingSuccessBlock)successBlock:(WLObjectBlock)success withObject:(WLMapResponseBlock)objectBlock failure:(WLFailureBlock)failure {
	return ^(AFHTTPRequestOperation *operation, id responseObject) {
		WLAPIResponse* response = [WLAPIResponse response:responseObject];
		if (response.code == WLAPIResponseCodeSuccess) {
            WLLog(@"RESPONSE",[operation.request.URL relativeString], responseObject);
#warning need to think how to perform it in background
            success(objectBlock(response));
		} else {
            WLLog(@"API ERROR",[operation.request.URL relativeString], responseObject);
			failure([NSError errorWithDescription:response.message code:response.code]);
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
        if (!signedIn) {
            signedIn = YES;
            [WLUploading enqueueAutomaticUploading:^{ }];
        }
        
		WLUser* user = [WLUser API_entry:[response.data dictionaryForKey:@"user"]];
		[user setCurrent];
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
		WLUser* user = [WLUser API_entry:[response.data objectForKey:@"user"]];
		[user setCurrent];
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
		WLUser* user = [WLUser API_entry:response.data[@"user"]];
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
		[weakSelf contributors:contacts success:success failure:failure];
	} failure:failure];
	return nil;
}

- (id)contributors:(NSArray*)contacts success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	if (contacts.count == 0) {
		success(nil);
		return nil;
	}
	
	NSMutableArray* phones = [NSMutableArray array];
	
	[contacts all:^(WLContact* contact) {
		[contact.phones all:^(WLPhone* phone) {
			[phones addObject:phone.number];
		}];
	}];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [self contributorsFromResponse:response contacts:contacts];
	};
	
	return [self POST:@"users/sign_up_status"
		parameters:@{@"phone_numbers":phones}
		   success:[self successBlock:success withObject:objectBlock failure:failure]
		   failure:[self failureBlock:failure]];
}

- (NSArray*)contributorsFromResponse:(WLAPIResponse*)response contacts:(NSArray*)contacts {
	NSArray* users = response.data[@"users"];
	[contacts all:^(WLContact* contact) {
		[contact.phones all:^(WLPhone* phone) {
			for (NSDictionary* userData in users) {
				if ([userData[@"address_book_number"] isEqualToString:phone.number]) {
					NSString* label = phone.number.label;
                    WLUser * user = [WLUser API_entry:userData];
                    phone.user = user;
					if (user.name.nonempty) {
						contact.name = user.name;
					} else {
						user.name = contact.name;
					}
					user.phone.label = label;
				}
			}
		}];
	}];
	return contacts;
}

- (id)wraps:(NSInteger)page success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {

	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(page) forKey:@"page"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		NSOrderedSet* wraps = [WLWrap API_entries:[response.data arrayForKey:@"wraps"]];
		if (page == 1 && wraps.nonempty) {
			NSOrderedSet* candies = [WLCandy API_entries:[response.data arrayForKey:@"recent_candies"]];
			if (candies.nonempty) {
				WLWrap* wrap = [wraps firstObject];
                [wrap addCandies:candies];
				[wrap save];
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
		return [wrap update:response.data[@"wrap"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)dates:(WLWrap *)wrap page:(NSUInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    if (!wrap.uploaded) {
        success(wrap);
        return nil;
    }
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@([[NSTimeZone localTimeZone] secondsFromGMT]) forKey:@"utc_offset"];
	[parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
	[parameters trySetObject:@(page) forKey:@"group_by_date_page_number"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [wrap update:response.data[@"wrap"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (NSDictionary*)parametersForWrap:(WLWrap*)wrap creation:(BOOL)creation {
	NSMutableArray* contributors = [NSMutableArray array];
	NSMutableArray* invitees = [NSMutableArray array];
	for (WLUser* contributor in wrap.contributors) {
		if (creation) {
            if (![contributor isCurrentUser]) {
                [contributors addObject:contributor.identifier];
            }
        } else {
            [contributors addObject:contributor.identifier];
        }
	}
    for (WLPhone * phone in wrap.invitees) {
        NSData* invitee = [NSJSONSerialization dataWithJSONObject:@{@"name":WLString(phone.name),@"phone_number":phone.number} options:0 error:NULL];
        [invitees addObject:[[NSString alloc] initWithData:invitee encoding:NSUTF8StringEncoding]];
    }
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:wrap.name forKey:@"name"];
	[parameters trySetObject:contributors forKey:@"user_uids"];
	[parameters trySetObject:invitees forKey:@"invitees"];
    if (creation) {
        [parameters trySetObject:wrap.uploadIdentifier forKey:@"upload_uid"];
    }
	return parameters;
}

- (id)createWrap:(WLWrap *)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		WLWrap* _wrap = [wrap update:response.data[@"wrap"]];
		[_wrap broadcastCreation];
		return _wrap;
	};
	return [self POST:@"wraps"
		   parameters:[self parametersForWrap:wrap creation:YES]
			 filePath:wrap.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)updateWrap:(WLWrap *)wrap success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [wrap update:response.data[@"wrap"]];
	};
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	return [self PUT:path
          parameters:[self parametersForWrap:wrap creation:NO]
			 filePath:wrap.picture.large
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)leaveWrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	[wrap.contributors removeObject:[WLUser currentUser]];
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        [wrap remove];
		return response;
	};
	NSString* path = [NSString stringWithFormat:@"wraps/%@", wrap.identifier];
	return [self PUT:path
		  parameters:[self parametersForWrap:wrap creation:NO]
			filePath:wrap.picture.large
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)removeWrap:(WLWrap *)wrap success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        [wrap remove];
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

- (id)addCandy:(WLCandy *)candy success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:candy.uploadIdentifier forKey:@"upload_uid"];
	[parameters trySetObject:@([candy.updatedAt timestamp]) forKey:@"contributed_at_in_epoch"];
	if ([candy isMessage]) {
		[parameters trySetObject:candy.message forKey:@"chat_message"];
	}
    
    WLPicture* picture = [candy.picture copy];
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        [candy API_setup:[response.data dictionaryForKey:@"candy"]];
        if ([candy isImage]) {
			[[WLImageCache cache] setImageAtPath:picture.medium withUrl:candy.picture.medium];
			[[WLImageCache cache] setImageAtPath:picture.small withUrl:candy.picture.small];
			[[WLImageCache cache] setImageAtPath:picture.large withUrl:candy.picture.large];
		}
        candy.wrap.updatedAt = candy.updatedAt;
        [candy broadcastChange];
        [candy save];
		return candy;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", candy.wrap.identifier];
	
	return [self POST:path
		   parameters:parameters
			 filePath:([candy isImage] ? candy.picture.large : nil)
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
}

- (id)olderCandies:(WLWrap *)wrap referenceCandy:(WLCandy *)referenceCandy withinDay:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {

	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(withinDay) forKey:@"same_day"];
	[parameters trySetObject:@(referenceCandy.updatedAt.timestamp) forKey:@"offset_x_in_epoch"];
    [parameters trySetObject:@(referenceCandy.updatedAt.timestamp) forKey:@"offset_y_in_epoch"];
    [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        NSOrderedSet* candies = [WLCandy API_entries:response.data[@"candies"] relatedEntry:wrap];
        [wrap addCandies:candies];
        [wrap save];
		return candies;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)olderCandies:(WLWrap *)wrap success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self olderCandies:wrap referenceCandy:[wrap.candies lastObject] withinDay:NO success:success failure:failure];
}

- (id)newerCandies:(WLWrap *)wrap referenceCandy:(WLCandy *)referenceCandy withinDay:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(withinDay) forKey:@"same_day"];
	[parameters trySetObject:@(referenceCandy.updatedAt.timestamp) forKey:@"offset_x_in_epoch"];
    [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		NSOrderedSet* candies = [WLCandy API_entries:response.data[@"candies"] relatedEntry:wrap];
        [wrap addCandies:candies];
		return candies;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)newerCandies:(WLWrap *)wrap success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self newerCandies:wrap referenceCandy:[wrap.candies firstObject] withinDay:NO success:success failure:failure];
}

- (id)freshCandies:(WLWrap *)wrap success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters trySetObject:[[NSTimeZone localTimeZone] name] forKey:@"tz"];
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        NSOrderedSet* candies = [WLCandy API_entries:response.data[@"candies"]];
        [wrap addCandies:candies];
		return candies;
	};
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies", wrap.identifier];
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)removeCandy:(WLCandy *)candy success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        [candy remove];
		return response;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier];
	return [self DELETE:path
			 parameters:nil
				success:[self successBlock:success withObject:objectBlock failure:failure]
				failure:[self failureBlock:failure]];
}

- (id)messages:(WLWrap *)wrap page:(NSUInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@(page) forKey:@"page"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        NSOrderedSet* messages = [WLCandy API_entries:response.data[@"chat_messages"] relatedEntry:wrap];
        if (messages.nonempty) {
            [wrap addCandies:messages];
            [wrap broadcastChange];
        }
		return messages;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/chat_messages", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)latestMessage:(WLWrap *)wrap success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:@"latest" forKey:@"latest"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		NSOrderedSet* messages = [WLCandy API_entries:response.data[@"chat_messages"] relatedEntry:wrap];
        if (messages.nonempty) {
            [wrap addCandies:messages];
            [wrap broadcastChange];
        }
		return [messages firstObject];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/chat_messages", wrap.identifier];
	
	return [self GET:path
		  parameters:parameters
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)candy:(WLCandy *)candy success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
		return [candy update:[response.data dictionaryForKey:@"candy"]];
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@", candy.wrap.identifier, candy.identifier];

	return [self GET:path
		  parameters:nil
			 success:[self successBlock:success withObject:objectBlock failure:failure]
			 failure:[self failureBlock:failure]];
}

- (id)addComment:(WLComment*)comment success:(WLCommentBlock)success failure:(WLFailureBlock)failure {
	NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
	[parameters trySetObject:comment.text forKey:@"message"];
    [parameters trySetObject:comment.uploadIdentifier forKey:@"upload_uid"];
    [parameters trySetObject:@(comment.updatedAt.timestamp) forKey:@"contributed_at_in_epoch"];
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        [comment API_setup:[response.data dictionaryForKey:@"comment"]];
        [comment.candy touch:comment.createdAt];
        [comment broadcastChange];
        [comment save];
		return comment;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@/comments", comment.candy.wrap.identifier, comment.candy.identifier];
	
	return [self POST:path
		   parameters:parameters
			  success:[self successBlock:success withObject:objectBlock failure:failure]
			  failure:[self failureBlock:failure]];
	
}

- (id)removeComment:(WLComment *)comment success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	
	WLMapResponseBlock objectBlock = ^id(WLAPIResponse *response) {
        [comment remove];
		return response;
	};
	
	NSString* path = [NSString stringWithFormat:@"wraps/%@/candies/%@/comments/%@", comment.candy.wrap.identifier, comment.candy.identifier, comment.identifier];
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

- (id)checkUploading:(WLUploading *)uploading success:(WLBooleanBlock)success failure:(WLFailureBlock)failure {
    if (uploading.identifier.nonempty) {
        return [self uploadStatus:@[uploading.identifier] success:^(NSArray *array) {
            success([array containsObject:uploading.identifier]);
        } failure:failure];
    } else {
        failure([NSError errorWithDescription:@"Uploading is invalid."]);
        return nil;
    }
}

@end

@implementation WLEntry (WLAPIManager)

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    success(self);
    return nil;
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    success(self);
    return nil;
}

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    success(self);
    return nil;
}

@end

@implementation WLWrap (WLAPIManager)

- (id)add:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] createWrap:self success:success failure:failure];
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.uploading) {
        if (self.uploading.operation == nil) {
            [self remove];
            success(nil);
        } else {
            failure([NSError errorWithDescription:@"Wrap is uploading, wait a moment..."]);
        }
        return nil;
    } else {
        return [[WLAPIManager instance] removeWrap:self success:success failure:failure];
    }
}

- (id)fetch:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        return [[WLAPIManager instance] wrap:self success:success failure:failure];
    } else {
        success(self);
        return nil;
    }
}

- (id)update:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] updateWrap:self success:success failure:failure];
}

- (id)fetch:(NSInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] wrap:self page:page success:success failure:failure];
}

- (id)olderCandies:(WLCandy*)referenceCandy withinDay:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] olderCandies:self referenceCandy:referenceCandy withinDay:withinDay success:success failure:failure];
}

- (id)olderCandies:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self olderCandies:[self.candies lastObject] withinDay:NO success:success failure:failure];
}

- (id)newerCandies:(WLCandy*)referenceCandy withinDay:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] newerCandies:self referenceCandy:referenceCandy withinDay:withinDay success:success failure:failure];
}

- (id)newerCandies:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self newerCandies:[self.candies firstObject] withinDay:NO success:success failure:failure];
}

- (id)freshCandies:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] freshCandies:self success:success failure:failure];
}

- (id)messages:(NSUInteger)page success:(WLArrayBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] messages:self page:page success:success failure:failure];
}

- (id)latestMessage:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] latestMessage:self success:success failure:failure];
}

- (id)leave:(WLObjectBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] leaveWrap:self success:success failure:failure];
}

@end

@implementation WLCandy (WLAPIManager)

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] addCandy:self success:success failure:failure];
}

- (id)remove:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.uploading) {
        if (self.uploading.operation == nil) {
            [self remove];
            success(nil);
        } else {
            failure([NSError errorWithDescription:@"Photo is uploading, wait a moment..."]);
        }
        return nil;
    } else {
        return [[WLAPIManager instance] removeCandy:self success:success failure:failure];
    }
}

- (id)fetch:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	return [[WLAPIManager instance] candy:self success:success failure:failure];
}

- (id)olderCandies:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] olderCandies:self.wrap referenceCandy:self withinDay:withinDay success:success failure:failure];
}

- (id)newerCandies:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] newerCandies:self.wrap referenceCandy:self withinDay:withinDay success:success failure:failure];
}

@end

@implementation WLComment (WLAPIManager)

- (id)add:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] addComment:self success:success failure:failure];
}

- (id)remove:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    if (self.uploading) {
        if (self.uploading.operation == nil) {
            [self remove];
            success(nil);
        } else {
            failure([NSError errorWithDescription:@"Comment is uploading, wait a moment..."]);
        }
        return nil;
    } else {
        return [[WLAPIManager instance] removeComment:self success:success failure:failure];
    }
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

@implementation WLUploading (WLAPIManager)

- (id)check:(WLBooleanBlock)success failure:(WLFailureBlock)failure {
    return [[WLAPIManager instance] checkUploading:self success:success failure:failure];
}

@end
