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

@property (strong, nonatomic) NSString* urlScheme;

@property (readonly, nonatomic) BOOL isProduction;

+ (instancetype)environmentNamed:(NSString*)name;

@end
