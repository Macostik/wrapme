//
//  NSError+CustomErrors.m
//  Pressgram
//
//  Created by Sergey Maximenko on 30.11.13.
//  Copyright (c) 2013 yo, gg. All rights reserved.
//

#import "NSError+WLAPIManager.h"
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import "WLToast.h"

@implementation NSError (WLAPIManager)

static NSDictionary *errorsToIgnore = nil;

+ (NSDictionary*)errorsToIgnore {
	if (!errorsToIgnore) {
		errorsToIgnore = @{};
	}
	return errorsToIgnore;
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

- (void)show {
	[self showWithTitle:@"Something went wrong..."];
}

- (void)showWithTitle:(NSString *)title {
	[self showWithTitle:title callback:nil];
}

- (void)showWithTitle:(NSString *)title callback:(void (^)(void))callback {
	if (![self ignore]) {
		[WLToast showWithMessage:[self errorMessage]?:self.localizedDescription];
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
		customErrorMessages = @{NSURLErrorDomain:@{@(NSURLErrorTimedOut):@"Connection was lost.",
												   @(NSURLErrorInternationalRoamingOff):@"International roaming is off."}};
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

- (void)log {
	[self log:@"Something went wrong..."];
}

- (void)log:(NSString *)label {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
	    if (![self ignore])
            WLLog(@"ERROR",label, self);
	});
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
