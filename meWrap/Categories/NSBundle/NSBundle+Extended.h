//
//  NSBundle+Extended.h
//  meWrap
//
//  Created by Ravenpod on 22.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
#import <Foundation/Foundation.h>

#define NSMainBundle [NSBundle mainBundle]

@protocol NSBundleExtended <NSObject>

+ (instancetype)plist:(NSString*)name;

@end

@interface NSBundle (Extended)

@property (readonly, nonatomic) NSString *displayName;

@property (readonly, nonatomic) NSString *buildVersion;

@property (readonly, nonatomic) NSString *buildNumber;

- (NSString*)plist:(NSString *)name;

@end

@interface NSArray (NSBundleExtended) <NSBundleExtended> @end

@interface NSDictionary (NSBundleExtended) <NSBundleExtended> @end
