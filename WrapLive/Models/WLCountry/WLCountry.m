//
//  WLCountry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCountry.h"

@implementation WLCountry

+ (JSONKeyMapper *)keyMapper {
	return [[JSONKeyMapper alloc] initWithDictionary:@{@"dial_code":@"callingCode"}];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
	return YES;
}

+ (NSArray *)getAllCountries {
	NSArray* json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CountryCodes" ofType:@"json"]] options:NSJSONReadingAllowFragments error:NULL];
	
	return [WLCountry arrayOfModelsFromDictionaries:json];
}

+ (WLCountry *)getCurrentCountry {
	NSString * code = [[NSLocale componentsFromLocaleIdentifier:[[NSLocale currentLocale] identifier]] objectForKey:NSLocaleCountryCode];
	
	for (WLCountry * country in [WLCountry getAllCountries]) {
		if ([country.code isEqualToString:code]) {
			return country;
		}
	}
	return nil;
}

@end
