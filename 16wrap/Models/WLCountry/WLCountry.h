//
//  WLCountry.h
//  moji
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

@interface WLCountry : NSObject

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* callingCode;
@property (strong, nonatomic) NSString* code;

+ (NSMutableOrderedSet *)all;
+ (WLCountry *)getCurrentCountry;

@end
