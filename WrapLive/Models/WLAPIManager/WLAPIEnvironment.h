//
//  WLAPIConfiguration.h
//  WrapLive
//
//  Created by Sergey Maximenko on 9/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* WLAPIEnvironmentDevelopment = @"development";
static NSString* WLAPIEnvironmentQA = @"qa";
static NSString* WLAPIEnvironmentBeta = @"beta";
static NSString* WLAPIEnvironmentProduction = @"production";

@interface WLAPIEnvironment : NSObject

@property (strong, nonatomic) NSString* name;

@property (strong, nonatomic) NSString* endpoint;

@property (strong, nonatomic) NSString* version;

@property (strong, nonatomic) NSString* testUsersPropertyListName;

@property (nonatomic) BOOL useTestUsers;

+ (instancetype)configuration:(NSString*)name;

- (void)testUsers:(void (^)(NSArray* testUsers))completion;

@end
