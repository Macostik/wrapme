//
//  WLEntry.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "JSONModel.h"

@class WLUser;

@interface WLEntry : JSONModel

@property (strong, nonatomic) WLUser* author;
@property (strong, nonatomic) NSDate* createdAt;
@property (strong, nonatomic) NSString* identifier;

@end
