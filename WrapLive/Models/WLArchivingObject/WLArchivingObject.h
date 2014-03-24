//
//  WLArchivingObject.h
//  WrapLive
//
//  Created by Sergey Maximenko on 21.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <JSONModel/JSONModel.h>

@interface WLArchivingObject : JSONModel

- (NSData*)data;
- (void)data:(void (^)(NSData* data))completion;
+ (id)objectWithData:(NSData*)data;
+ (void)objectWithData:(NSData*)data completion:(void (^)(id object))completion;

@end
