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
#import "NSString+Additions.h"
#import "NSArray+Additions.h"

@implementation WLCountry

+ (NSArray *)getAllCountries {
	NSArray* json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CountryCodes" ofType:@"json"]] options:NSJSONReadingAllowFragments error:NULL];
    return [json map:^id(NSDictionary* item) {
        WLCountry* country = [[WLCountry alloc] init];
        country.name = [item objectForKey:@"name"];
        country.callingCode = [item objectForKey:@"dial_code"];
        country.code = [item objectForKey:@"code"];
        return country;
    }];
}

+ (WLCountry *)getCurrentCountry {
	CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	NSString *code = [[[networkInfo subscriberCellularProvider] isoCountryCode] lowercaseString];
	if (!code.nonempty) {
		code = [[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] lowercaseString];
	}
	NSArray* countries = [WLCountry getAllCountries];
	for (WLCountry * country in countries) {
		if ([[country.code lowercaseString] isEqualToString:code]) {
			return country;
		}
	}
	return [countries firstObject];
}

@end
