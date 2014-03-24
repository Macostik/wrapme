//
//  UIFont+CustomFonts.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIFont+CustomFonts.h"

@implementation UIFont (CustomFonts)

+ (NSString*)fontNameWithType:(WLFontType)type {
	switch (type) {
		case WLFontTypeOpenSansRegular:
			return WLFontNameOpenSansRegular;
			break;
		case WLFontTypeOpenSansLight:
			return WLFontNameOpenSansLight;
			break;
	}
	return nil;
}

+ (UIFont*)fontWithType:(WLFontType)type size:(CGFloat)size {
	NSString* fontName = [self fontNameWithType:type];
	if (fontName) {
		return [UIFont fontWithName:fontName size:size];
	}
	return nil;
}

- (UIFont*)fontWithType:(WLFontType)type {
	UIFont* font = [UIFont fontWithType:type size:self.pointSize];
	if (font) {
		return font;
	} else {
		return self;
	}
}

@end
