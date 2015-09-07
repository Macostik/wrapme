//
//  WLCountry.m
//  meWrap
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCountry.h"
#import "WLTelephony.h"

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
	NSString *code = [WLTelephony countryCode];
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
