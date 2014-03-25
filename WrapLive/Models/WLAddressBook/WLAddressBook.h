//
//  WLAddressBook.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLAddressBook : NSObject

+ (void)users:(void (^)(NSArray* users))success failure:(void (^)(NSError* error))failure;

@end
