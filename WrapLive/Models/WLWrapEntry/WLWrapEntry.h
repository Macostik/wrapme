//
//  WLWrapEntry.h
//  WrapLive
//
//  Created by Sergey Maximenko on 01.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@class WLUser;

@interface WLWrapEntry : WLEntry

@property (strong, nonatomic) WLUser* author;

@property (strong, nonatomic) NSDate* contributedAt;

@end
