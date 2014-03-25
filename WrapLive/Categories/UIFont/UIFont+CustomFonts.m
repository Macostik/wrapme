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

+ (UIFont*)lightFontOfSize:(CGFloat)size {
	return [self fontWithType:WLFontTypeOpenSansLight size:size];
}

+ (UIFont*)lightMicroFont {
	return [self lightFontOfSize:WLFontSizeMicro];
}

+ (UIFont*)lightSmallFont {
	return [self lightFontOfSize:WLFontSizeSmall];
}

+ (UIFont*)lightNormalFont {
	return [self lightFontOfSize:WLFontSizeNormal];
}

+ (UIFont*)lightLargeFont {
	return [self lightFontOfSize:WLFontSizeLarge];
}

+ (UIFont*)regularFontOfSize:(CGFloat)size {
	return [self fontWithType:WLFontTypeOpenSansRegular size:size];
}

+ (UIFont*)regularMicroFont {
	return [self regularFontOfSize:WLFontSizeMicro];
}

+ (UIFont*)regularSmallFont {
	return [self regularFontOfSize:WLFontSizeSmall];
}

+ (UIFont*)regularNormalFont {
	return [self regularFontOfSize:WLFontSizeNormal];
}

+ (UIFont*)regularLargeFont {
	return [self regularFontOfSize:WLFontSizeLarge];
}

@end

@implementation UILabel (CustomFonts)

- (void)awakeFromNib {
	self.font = [self.font fontWithType:self.tag];
}

@end

@implementation UIButton (CustomFonts)

- (void)awakeFromNib {
	self.titleLabel.font = [self.titleLabel.font fontWithType:self.tag];
}

@end

@implementation UITextField (CustomFonts)

- (void)awakeFromNib {
	self.font = [self.font fontWithType:self.tag];
}

@end

@implementation UITextView (CustomFonts)

- (void)awakeFromNib {
	self.font = [self.font fontWithType:self.tag];
}

@end
