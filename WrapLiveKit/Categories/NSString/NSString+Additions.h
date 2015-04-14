//
//  NSString+Hash.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 4/3/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+NibAdditions.h"

static inline NSString* GUID() {
	return [[NSProcessInfo processInfo] globallyUniqueString];
}

static inline BOOL NSStringEqual(NSString* s1, NSString* s2) {
    return (s1 == nil) ? (s2 == nil) : ((s2 == nil) ? (s1 == nil) : [s1 isEqualToString:s2]);
}

static inline BOOL NSNumberEqual(NSNumber* n1, NSNumber* n2) {
    return (n1 == nil) ? (n2 == nil) : ((n2 == nil) ? (n1 == nil) : [n1 isEqualToNumber:n2]);
}

static inline BOOL NSDateEqual(NSDate* d1, NSDate* d2) {
    return (d1 == nil) ? (d2 == nil) : ((d2 == nil) ? (d1 == nil) : [d1 isEqualToDate:d2]);
}

static inline NSString* WLString(NSString* string) {
	return string?:@"";
};

static inline NSString* phoneNumberClearing (NSString* phone) {
	NSMutableString* _phone = [NSMutableString string];
	for (NSInteger index = 0; index < phone.length; ++index) {
		NSString* character = [phone substringWithRange:NSMakeRange(index, 1)];
		if ([character rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound) {
			[_phone appendString:character];
		} else if ([character rangeOfString:@"+"].location != NSNotFound) {
			[_phone appendString:character];
		}
	}
	return [_phone copy];
}

static inline CGFloat WLCalculateHeightString(NSString *string, UIFont *font, CGFloat width) {
    static UITextView *textView = nil;
    if (!textView) {
        textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];
        textView.textContainerInset = UIEdgeInsetsZero;
    }
    textView.text = string;
    textView.font = font;
    return [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)].height;
}

@interface NSString (Additions)

@property (nonatomic, readonly) BOOL empty;

@property (nonatomic, readonly) BOOL nonempty;

- (BOOL)isValidEmail;

- (NSString*)trim;

- (BOOL)matches:(NSString *)string, ... NS_REQUIRES_NIL_TERMINATION;

- (CGFloat)heightWithFont:(UIFont*)font width:(CGFloat)width cachingKey:(char *)key;

- (CGFloat)heightWithFont:(UIFont*)font width:(CGFloat)width;

- (CGFloat)widthWithFont:(UIFont*)font size:(CGSize)size;

- (NSString*)stringByCapitalizingFirstCharacter;

- (NSDictionary *)URLQueryParameters;

@end

@interface NSNumber (Additions)

- (BOOL)isEqualToInteger:(NSInteger)integer;

@end