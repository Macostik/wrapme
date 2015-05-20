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
#import "NSArray+Additions.h"
#import "WLAddressBook.h"
#import "WLEntryNotifier.h"
#import "NSString+Additions.h"
#import "WLAuthorization.h"
#import "NSDate+Additions.h"
#import "WLWelcomeViewController.h"
#import "WLImageCache.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLAddWrapRequest.h"
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
#import "WLUploadMessageRequest.h"
#import "WLEntityRequest.h"
#import "WLLeaveWrapRequest.h"
#import "WLOperationQueue.h"
#import "WLHistory.h"
#import "NSUserDefaults+WLAppGroup.h"
#import "WLAlertView.h"

static NSString* WLAPILocalUrl = @"http://192.168.33.10:3000/api";

typedef void (^WLAFNetworkingSuccessBlock) (AFHTTPRequestOperation *operation, id responseObject);
typedef void (^WLAFNetworkingFailureBlock) (AFHTTPRequestOperation *operation, NSError *error);

#define WLAPIEnvironmentDefault WLAPIEnvironmentDevelopment

@implementation WLAPIManager

+ (instancetype)manager {
    static WLAPIManager* instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        WLAPIEnvironment* environment = [self initializationEnvironment];
        WLLog(environment.endpoint, @"API environment initialized", environment.name);
        instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:environment.endpoint]];
        instance.environment = environment;
		instance.requestSerializer.timeoutInterval = 45;
        NSString* acceptHeader = [NSString stringWithFormat:@"application/vnd.ravenpod+json;version=%@", environment.version];
		[instance.requestSerializer setValue:acceptHeader forHTTPHeaderField:@"Accept"];
        instance.securityPolicy.allowInvalidCertificates = YES;
	});
    return instance;
}

+ (WLAPIEnvironment*)initializationEnvironment {
    NSString* environmentName = [[[NSBundle mainBundle] infoDictionary] stringForKey:WLAPIEnvironmentKey];
    if (!environmentName.nonempty) {
        environmentName = [[NSUserDefaults appGroupUserDefaults] objectForKey:WLAPIEnvironmentKey];
    } else {
#ifndef WRAPLIVE_EXTENSION_TERGET
        [self saveEnvironmentName:environmentName];
#endif
    }
    if (!environmentName.nonempty) environmentName = WLAPIEnvironmentDefault;
    
    return [WLAPIEnvironment environmentNamed:environmentName];
}

+ (void)saveEnvironmentName:(NSString*)environmentName {
    NSUserDefaults *userDefaults = [NSUserDefaults appGroupUserDefaults];
    [userDefaults setObject:environmentName forKey:WLAPIEnvironmentKey];
    [userDefaults synchronize];
}

- (NSString *)urlWithPath:(NSString *)path {
    return [[NSURL URLWithString:path relativeToURL:self.baseURL] absoluteString];
}

@end

@implementation WLEntry (WLAPIManager)

- (BOOL)fetched {
    return YES;
}

- (BOOL)recursivelyFetched {
    WLEntry *entry = self;
    while (entry) {
        if (!entry.fetched) {
            return NO;
        }
        entry = entry.containingEntry;
    }
    return YES;
}

- (void)recursivelyFetchIfNeeded:(WLBlock)success failure:(WLFailureBlock)failure {
    
    if (self.recursivelyFetched) {
        if (success) success();
        return;
    }
    
    WLEntry *entry = self;
    while (entry) {
        runUnaryQueuedOperation(@"recursive_entry_fetching", ^(WLOperation *operation) {
            [entry fetchIfNeeded:^ (WLEntry *entry) {
                [operation finish:success];
            } failure:^ (NSError *error) {
                [operation.queue cancelAllOperations];
                [operation finish];
                if (failure) failure(error);
            }];
        });
        entry = entry.containingEntry;
    }
}

- (id)fetchIfNeeded:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.fetched) {
        if (success) success(self);
        return nil;
    } else {
        __weak typeof(self)weakSelf = self;
        runQueuedOperation(@"entry_fetching", 3, ^(WLOperation *operation) {
            [weakSelf fetch:^(id object) {
                [operation finish];
                if (success) success(object);
            } failure:^(NSError *error) {
                [operation finish];
                if (failure) failure(error);
            }];
        });
        return nil;
    }
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
    [self remove:YES success:success failure:failure];
    return nil;
}

- (id)remove:(BOOL)confirm success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(self);
    return nil;
}

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    return [[WLEntityRequest request:self] send:success failure:failure];
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

static NSString *const WLDeleteAlertTitle = @"Delete wrap";
static NSString *const WLLeaveAlertTitle = @"Leave wrap?";
static NSString *const WLDeleteAlertMessage = @"Are you sure you want to delete the wrap \"%@\"?";
static NSString *const WLLeaveAlertMessage  = @"Are you sure you want to leave this wrap";

@implementation WLWrap (WLAPIManager)

- (BOOL)fetched {
    return self.name.nonempty && self.contributor;
}

- (id)add:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    return [[WLAddWrapRequest request:self] send:success failure:failure];
}

- (id)remove:(BOOL)confirm success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    void (^removeBlock)(void) = ^{
        switch (self.status) {
            case WLContributionStatusReady:
                [weakSelf remove];
                if (success) success(nil);
                break;
            case WLContributionStatusInProgress:
                if (failure) failure([NSError errorWithDescription:WLLS(@"Wrap is uploading, wait a moment...")]);
                break;
            case WLContributionStatusUploaded: {
                [[WLDeleteWrapRequest request:weakSelf] send:^(id object) {
                    if (success) success(object);
                } failure:failure];
            }   break;
            default:
                break;
        }
    };
    if (!confirm) {
        removeBlock();
        return nil;
    }
    [WLAlertView showWithTitle:WLLS(WLDeleteAlertTitle)
                       message:[NSString stringWithFormat:WLLS(WLDeleteAlertMessage), self.name]
                       buttons:@[WLLS(@"Cancel"),WLLS(@"Delete")]
                    completion:^(NSUInteger index) {
                        if (index == 1) {
                            removeBlock();
                        } else if (failure) {
                            failure([NSError errorWithDescription:@"Action cancelled" code:WLErrorActionCancelled]);
                        }
                    }];
    return nil;
}

- (id)fetch:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    return [self fetch:WLWrapContentTypeRecent success:success failure:failure];
}

- (id)fetch:(NSString*)contentType success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        WLWrapRequest* request = [WLWrapRequest request:self];
        request.contentType = contentType;
        return [request send:success failure:failure];
    } else if (success) {
        success(nil);
    }
    return nil;
}

- (id)update:(WLWrapBlock)success failure:(WLFailureBlock)failure {
    return [[WLUploadWrapRequest request:self] send:success failure:failure];
}

- (id)messagesNewer:(NSDate *)newer success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLMessagesRequest* request = [WLMessagesRequest request:self];
    request.type = WLPaginatedRequestTypeNewer;
    request.newer = newer;
    return [request send:success failure:failure];
}

- (id)messagesOlder:(NSDate *)older newer:(NSDate *)newer success:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLMessagesRequest* request = [WLMessagesRequest request:self];
    request.type = WLPaginatedRequestTypeOlder;
    request.newer = newer;
    request.older = older;
    return [request send:success failure:failure];
}

- (id)messages:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure {
    WLMessagesRequest* request = [WLMessagesRequest request:self];
    request.type = WLPaginatedRequestTypeFresh;
    return [request send:success failure:failure];
}

- (id)latestMessage:(WLMessageBlock)success failure:(WLFailureBlock)failure {
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
    __weak __typeof(self)weakSelf = self;
    [WLAlertView showWithTitle:WLLS(WLLeaveAlertTitle)
                       message:WLLS(WLLeaveAlertMessage)
                       buttons:@[WLLS(@"YES"),WLLS(@"NO")]
                    completion:^(NSUInteger index) {
                        if (!index) {
                            [[WLLeaveWrapRequest request:weakSelf] send:^(id object) {
                                [weakSelf remove];
                                success(object);
                            } failure:failure];
                        } else {
                            success(nil);
                        }
                    }];
    return nil;
}

- (void)preload {
    WLHistory *history = [WLHistory historyWithWrap:self];
    [history fresh:^(NSOrderedSet *orderedSet) {
        [history.entries enumerateObjectsUsingBlock:^(WLHistoryItem* item, NSUInteger idx, BOOL *stop) {
            [item.entries enumerateObjectsUsingBlock:^(WLCandy* candy, NSUInteger idx, BOOL *stop) {
                [candy.picture fetch:nil];
                if (idx == 5) *stop = YES;
            }];
            if (idx == 4) *stop = YES;
        }];
    } failure:nil];
}

@end

@implementation WLCandy (WLAPIManager)

- (BOOL)fetched {
    return self.picture.medium.nonempty;
}

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLUploadCandyRequest request:self] send:success failure:failure];
}

- (id)remove:(BOOL)confirm success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    void (^removeBlock) (void) = ^ {
        switch (weakSelf.status) {
            case WLContributionStatusReady:
                [weakSelf remove];
                if (success) success(nil);
                break;
            case WLContributionStatusInProgress: {
                if (failure) failure([NSError errorWithDescription:WLLS(@"Photo is uploading, wait a moment...")]);
            } break;
            case WLContributionStatusUploaded: {
                [[WLDeleteCandyRequest request:weakSelf] send:success failure:failure];
            } break;
            default:
                break;
        }
    };
    
    if (!confirm) {
        removeBlock();
        return nil;
    }
    [WLAlertView showWithTitle:WLLS(@"Delete photo")
                       message:WLLS(@"Are you sure you want to delete this photo?")
                       buttons:@[WLLS(@"Cancel"),WLLS(@"OK")]
                    completion:^(NSUInteger index) {
                        if (index == 1) {
                            removeBlock();
                        } else if (failure) {
                            failure(nil);
                        }
                    }];
    return nil;
}

- (id)fetchIfNeeded:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    return [super fetchIfNeeded:^(id object){
        [weakSelf.picture fetch:^{
            if (success) success(object);
        }];
    } failure:failure];
}

- (void)recursivelyFetchIfNeeded:(WLBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [super recursivelyFetchIfNeeded:^ {
        [weakSelf.picture fetch:success];
    } failure:failure];
}

- (id)fetch:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (self.uploaded) {
        return [[WLCandyRequest request:self] send:success failure:failure];
    } else {
        if (failure) failure([NSError errorWithDescription:WLLS(@"Photo is uploading, wait a moment...")]);
        return nil;
    }
}

@end

@implementation WLMessage (WLAPIManager)

- (BOOL)fetched {
    return self.text.nonempty;
}

- (id)add:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    return [[WLUploadMessageRequest request:self] send:success failure:failure];
}

@end

@implementation WLComment (WLAPIManager)

- (BOOL)fetched {
    return self.text.nonempty;
}

- (id)add:(WLCommentBlock)success failure:(WLFailureBlock)failure {
    if (self.candy.uploaded) {
        return [[WLPostCommentRequest request:self] send:success failure:failure];
    } else if (failure) {
        failure(nil);
    }
    return nil;
}

- (id)remove:(BOOL)confirm success:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    switch (self.status) {
        case WLContributionStatusReady:
            [self remove];
            if (success) success(nil);
            break;
        case WLContributionStatusInProgress:
            if (failure) failure([NSError errorWithDescription:WLLS(@"Comment is uploading, wait a moment...")]);
            break;
        case WLContributionStatusUploaded: {
            switch (self.candy.status) {
                case WLContributionStatusReady:
                    [self remove];
                    if (success) success(nil);
                    break;
                case WLContributionStatusInProgress:
                    if (failure) failure([NSError errorWithDescription:WLLS(@"Candy is uploading, wait a moment...")]);
                    break;
                case WLContributionStatusUploaded:
                    return [[WLDeleteCommentRequest request:self] send:success failure:failure];
                    break;
                default:
                    break;
            }
            return nil;
        }   break;
        default:
            break;
    }
    return nil;
}

@end
