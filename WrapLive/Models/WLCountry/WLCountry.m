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

+ (NSMutableOrderedSet *)all {
	NSArray* json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CountryCodes" ofType:@"json"]] options:NSJSONReadingAllowFragments error:NULL];
    NSMutableOrderedSet* countries = [[NSMutableOrderedSet alloc] init];
    for (NSDictionary* item in json) {
        WLCountry* country = [[WLCountry alloc] init];
        country.name = [item objectForKey:@"name"];
        country.callingCode = [item objectForKey:@"dial_code"];
        country.code = [item objectForKey:@"code"];
        [countries addObject:country];
    }
    return countries;
}

+ (WLCountry *)getCurrentCountry {
	CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
	NSString *code = [[[networkInfo subscriberCellularProvider] isoCountryCode] lowercaseString];
	if (!code.nonempty) {
		code = [[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] lowercaseString];
	}
	NSMutableOrderedSet* countries = [WLCountry all];
	for (WLCountry * country in countries) {
		if ([[country.code lowercaseString] isEqualToString:code]) {
			return country;
		}
	}
	return [countries firstObject];
}

@end
