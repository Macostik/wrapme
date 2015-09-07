//
//  NSError+CustomErrors.m
//  meWrap
//
//  Created by Ravenpod on 30.11.13.
//  Copyright (c) 2013 yo, gg. All rights reserved.
//

#import "NSError+WLAPIManager.h"
#import "WLEntry+WLAPIRequest.h"
#import "NSDictionary+Extended.h"

@implementation NSError (WLAPIManager)

static NSDictionary *errorsToIgnore = nil;

+ (NSDictionary*)errorsToIgnore {
	if (!errorsToIgnore) {
		errorsToIgnore = @{};
	}
	return errorsToIgnore;
}

+ (NSError *)errorWithResponse:(WLAPIResponse *)response {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo trySetObject:response.message forKey:NSLocalizedDescriptionKey];
    [userInfo trySetObject:response.data forKey:WLErrorResponseDataKey];
    return [[NSError alloc] initWithDomain:WLErrorDomain code:response.code userInfo:[userInfo copy]];
}

+ (NSError *)errorWithDescription:(NSString *)description code:(NSInteger)code {
	return [[NSError alloc] initWithDomain:WLErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey:description }];
}

+ (NSError *)errorWithDescription:(NSString *)description {
	return [NSError errorWithDescription:description code:WLErrorUnknown];
}

- (BOOL)ignore {
	return [[[NSError errorsToIgnore] objectForKey:self.domain] containsObject:@(self.code)];
}

static WLFailureBlock _showingBlock;

+ (void)setShowingBlock:(WLFailureBlock)showingBlock {
    _showingBlock = showingBlock;
}

- (void)show {
	if (![self ignore]) {
        if (_showingBlock) {
            _showingBlock(self);
        }
	}
}

- (void)showIgnoringNetworkError {
	if (![self isNetworkError]) {
		[self show];
	}
}

- (BOOL)isNetworkError {
    NSInteger code = self.code;
    switch (code) {
        case NSURLErrorTimedOut:
        case NSURLErrorCannotFindHost:
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorDNSLookupFailed:
        case NSURLErrorHTTPTooManyRedirects:
        case NSURLErrorResourceUnavailable:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorRedirectToNonExistentLocation:
        case NSURLErrorInternationalRoamingOff:
        case NSURLErrorSecureConnectionFailed:
        case NSURLErrorCannotLoadFromNetwork:
            return YES;
            break;
        default:
            return NO;
            break;
    }
}

static NSDictionary *customErrorMessages = nil;

+ (NSDictionary*)customErrorMessages {
	if (!customErrorMessages) {
		customErrorMessages = @{NSURLErrorDomain:@{@(NSURLErrorTimedOut):WLLS(@"connection_was_lost"),
												   @(NSURLErrorInternationalRoamingOff):WLLS(@"roaming_is_off")}};
	}
	return customErrorMessages;
}

- (NSString *)errorMessage {
	id domainMessageObject = [[NSError customErrorMessages] objectForKey:self.domain];
	if ([domainMessageObject isKindOfClass:[NSDictionary class]]) {
		return [domainMessageObject objectForKey:@(self.code)];
	} else if ([domainMessageObject isKindOfClass:[NSString class]]) {
		return domainMessageObject;
	} else {
		return nil;
	}
}

- (BOOL)isError:(WLErrorCode)code {
    return [self.domain isEqualToString:WLErrorDomain] && self.code == code;
}

- (BOOL)isDuplicatedUploading {
    return [self isError:WLErrorDuplicatedUploading];
}

- (BOOL)isContentUnavaliable {
    return [self isError:WLErrorContentUnavaliable];
}

@end
