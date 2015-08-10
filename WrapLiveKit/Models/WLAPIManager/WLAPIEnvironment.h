//
//  WLAPIConfiguration.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* WLAPIEnvironmentLocal = @"local";
static NSString* WLAPIEnvironmentQA = @"qa";
static NSString* WLAPIEnvironmentProduction = @"production";

@interface WLAPIEnvironment : NSObject

@property (strong, nonatomic) NSString* name;

@property (strong, nonatomic) NSString* endpoint;

@property (strong, nonatomic) NSString* version;

@property (readonly, nonatomic) BOOL isProduction;

+ (instancetype)environmentNamed:(NSString*)name;

+ (instancetype)currentEnvironment;

- (void)testUsers:(void (^)(NSArray* testUsers))completion;

@end
