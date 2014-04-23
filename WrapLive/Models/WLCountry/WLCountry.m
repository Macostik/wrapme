//
//  WLCountry.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCountry.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

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
	CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	NSString *code = [[networkInfo subscriberCellularProvider] isoCountryCode];
	if (code.length == 0) {
		code = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
	}
	NSArray* countries = [WLCountry getAllCountries];
	for (WLCountry * country in countries) {
		if ([country.code isEqualToString:code]) {
			return country;
		}
	}
	return [countries firstObject];
}

@end
