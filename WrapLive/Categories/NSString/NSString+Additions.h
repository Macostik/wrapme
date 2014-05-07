//
//  NSString+Hash.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 4/3/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>

static inline NSString* GUID() {
	return [[NSProcessInfo processInfo] globallyUniqueString];
}

static inline BOOL NSStringEqual(NSString* string1, NSString* string2) {
	if (string1 == nil && string2 == nil) {
		return YES;
	} else if (string1 == nil || string2 == nil) {
		return NO;
	}
	return [string1 isEqualToString:string2];
}

static inline NSString* WLString(NSString* string) {
	return string?:@"";
};

@interface NSString (Additions)

@property (nonatomic, readonly) BOOL empty;

@property (nonatomic, readonly) BOOL nonempty;

- (BOOL)isValidEmail;

- (NSString*)trim;

@end
