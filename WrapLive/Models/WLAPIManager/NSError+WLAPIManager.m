//
//  NSError+CustomErrors.m
//  Pressgram
//
//  Created by Sergey Maximenko on 30.11.13.
//  Copyright (c) 2013 yo, gg. All rights reserved.
//

#import "NSError+WLAPIManager.h"
#import <CocoaLumberjack/DDLog.h>

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
		[[[UIAlertView alloc] initWithTitle:title message:[self errorMessage] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
	}
}

static NSDictionary *customErrorMessages = nil;

+ (NSDictionary*)customErrorMessages {
	if (!customErrorMessages) {
		customErrorMessages = @{};
	}
	return customErrorMessages;
}

- (NSString *)errorMessage {
	id domainMessageObject = [[NSError customErrorMessages] objectForKey:self.domain];
	
	if ([domainMessageObject isKindOfClass:[NSDictionary class]]) {
		domainMessageObject = [domainMessageObject objectForKey:@(self.code)];
	}
	
	if (domainMessageObject && [domainMessageObject isKindOfClass:[NSString class]]) {
		return domainMessageObject;
	} else {
		return self.localizedDescription;
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
