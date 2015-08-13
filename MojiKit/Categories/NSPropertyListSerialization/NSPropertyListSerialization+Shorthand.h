//
//  NSPropertyListSerialization+Shorthand.h
//  moji
//
//  Created by Ravenpod on 22.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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
