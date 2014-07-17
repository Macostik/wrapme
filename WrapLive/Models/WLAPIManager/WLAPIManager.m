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
#import "WLPerson.h"
#import "WLUploadWrapRequest.h"
#import "WLAuthorizationRequest.h"
#import "WLWrapRequest.h"
#import "WLDeleteWrapRequest.h"
#import "WLUploadCandyRequest.h"
#import "WLCandiesRequest.h"
#import "WLCandyRequest.h"
#import "WLMessagesRequest.h"
#import "WLDeleteCandyRequest.h"
#import "WLDeleteCommentRequest.h"
#import "WLPostCommentRequest.h"

static NSString* WLAPILocalUrl = @"http://192.168.33.10:3000/api";
static NSString* WLAPIDevelopmentUrl = @"https://dev-api.wraplive.com/api";
static NSString* WLAPIQAUrl = @"https://qa-api.wraplive.com/api";
static NSString* WLAPIProductionUrl = @"https://api.wraplive.com/api";
#define WLAPIBaseUrl WLAPIDevelopmentUrl

static NSString* WLAPIVersion = @"3";

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

- (NSString *)urlWithPath:(NSString *)path {
    return [[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString];
}

@end

@implementation WLEntry (WLAPIManager)

+ (id)fresh:(id)relatedEntry success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    success(nil);
    return nil;
}

- (id)add:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    success(self);
    return nil;
}

- (id)update:(WLObjectBlock)success failure:(WLFailureBlock)failure {
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

- (id)older:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    success(nil);
    return nil;
}

- (id)older:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self older:NO success:success failure:failure];
}

- (id)newer:(BOOL)withinDay success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    success(nil);
    return nil;
}

- (id)newer:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self newer:NO success:success failure:failure];
}

@end

@implementation WLWrap (WLAPIManager)

- (id)add:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    return [[WLUploadWrapRequest request:self] send:success failure:failure];
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
        return [[WLDeleteWrapRequest request:self] send:success failure:failure];
    }
}

- (id)fetch:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        return [[WLWrapRequest request:self] send:success failure:failure];
    } else {
        success(self);
        return nil;
    }
}

- (id)update:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    return [[WLUploadWrapRequest request:self] send:success failure:failure];
}

- (id)fetch:(NSInteger)page success:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    return [[WLWrapRequest request:self page:page] send:success failure:failure];
}

- (id)messagesNewer:(NSDate *)newer success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLMessagesRequest* request = [WLMessagesRequest request:self];
    request.type = WLPaginatedRequestTypeNewer;
    request.newer = newer;
    return [request send:success failure:failure];
}

- (id)messagesOlder:(NSDate *)older success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLMessagesRequest* request = [WLMessagesRequest request:self];
    request.type = WLPaginatedRequestTypeOlder;
    request.newer = older;
    request.older = older;
    return [request send:success failure:failure];
}

- (id)messages:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLMessagesRequest* request = [WLMessagesRequest request:self];
    request.type = WLPaginatedRequestTypeFresh;
    return [request send:success failure:failure];
}

- (id)latestMessage:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    WLMessagesRequest* request = [WLMessagesRequest request:self];
    request.type = WLPaginatedRequestTypeFresh;
    request.latest = YES;
    return [request send:^(id object) {
        if (success) {
            success([object lastObject]);
        }
    } failure:failure];
}

- (id)leave:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.contributors removeObject:[WLUser currentUser]];
    return [self update:^(WLWrap *wrap) {
        [wrap remove];
        if (success) {
            success(nil);
        }
    } failure:failure];
}

@end

@implementation WLCandy (WLAPIManager)

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLUploadCandyRequest request:self] send:success failure:failure];
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
        return [[WLDeleteCandyRequest request:self] send:success failure:failure];
    }
}

- (id)fetch:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLCandyRequest request:self] send:success failure:failure];
}

@end

@implementation WLComment (WLAPIManager)

- (id)add:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    return [[WLPostCommentRequest request:self] send:success failure:failure];
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
        return [[WLDeleteCommentRequest request:self] send:success failure:failure];
    }
}

@end
