//
//  WLAuthorizationFlow.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLAuthorizationFlow : NSObject

@property (nonatomic) BOOL registrationNotCompleted;

- (instancetype)initWithNavigationController:(UINavigationController*)controller;

- (void)start;

@end
