//
//  WLAPIResponse.m
//  meWrap
//
//  Created by Ravenpod on 25.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAPIResponse.h"

@implementation WLAPIResponse

+ (instancetype)response:(NSDictionary *)dictionary {
    WLAPIResponse* response = [[self alloc] init];
    response.data = [dictionary dictionaryForKey:@"data"];
    response.code = [[dictionary numberForKey:@"return_code"] integerValue];
    response.message = [dictionary stringForKey:@"message"];
    return response;
}

@end
