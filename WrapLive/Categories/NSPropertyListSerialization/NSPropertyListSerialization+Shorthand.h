//
//  NSPropertyListSerialization+Shorthand.h
//  WrapLive
//
//  Created by Sergey Maximenko on 22.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//
#import <Foundation/Foundation.h>

@protocol NSPropertyListSerializationShorthand <NSObject>

+ (instancetype)resourcePropertyListNamed:(NSString*)name;

+ (instancetype)mutableResourcePropertyListNamed:(NSString*)name;

@end

@interface NSPropertyListSerialization (Shorthand) <NSPropertyListSerializationShorthand>

@end

@interface NSArray (NSPropertyListSerializationShorthand) <NSPropertyListSerializationShorthand>

@end

@interface NSDictionary (NSPropertyListSerializationShorthand) <NSPropertyListSerializationShorthand>

@end
