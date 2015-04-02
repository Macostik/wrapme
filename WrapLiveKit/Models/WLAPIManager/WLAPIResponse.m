//
//  WLAPIResponse.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLAPIResponse.h"
#import "NSDictionary+Extended.h"

@implementation WLAPIResponse

+ (instancetype)response:(NSDictionary *)dictionary {
    WLAPIResponse* response = [[self alloc] init];
    response.data = [dictionary dictionaryForKey:@"data"];
    response.code = [dictionary integerForKey:@"return_code"];
    response.message = [dictionary stringForKey:@"message"];
    return response;
}

@end
