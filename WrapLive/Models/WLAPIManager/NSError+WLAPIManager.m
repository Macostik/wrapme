//
//  NSError+CustomErrors.m
//  Pressgram
//
//  Created by Sergey Maximenko on 30.11.13.
//  Copyright (c) 2013 yo, gg. All rights reserved.
//

#import "NSError+WLAPIManager.h"
#import <CocoaLumberjack/DDLog.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>

static const int ddLogLevel = LOG_LEVEL_DEBUG;

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
	return [NSError errorWithDescription:description code:kWLErrorCodeUnknown];
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
		NSString* errorMessage = [self errorMessage];
		if (!errorMessage) {
			errorMessage = self.localizedDescription;
		}
		[[[UIAlertView alloc] initWithTitle:title message:errorMessage delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
	}
}

- (void)showIgnoringNetworkError {
	if (![self isNetworkError]) {
		[self show];
	}
}

- (BOOL)isNetworkError {
	return self.code == NSURLErrorNetworkConnectionLost || self.code == NSURLErrorNotConnectedToInternet;;
}

static NSDictionary *customErrorMessages = nil;

+ (NSDictionary*)customErrorMessages {
	if (!customErrorMessages) {
		customErrorMessages = @{AFNetworkingErrorDomain:@{@(NSURLErrorTimedOut):@"Connection was lost."}};
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
			DDLogDebug(@"%@: %@", label, self);
	});
}

@end
