//
//  WLCountry.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

@interface WLCountry : NSObject

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* callingCode;
@property (strong, nonatomic) NSString* code;

+ (NSArray *)getAllCountries;
+ (WLCountry *)getCurrentCountry;

@end
