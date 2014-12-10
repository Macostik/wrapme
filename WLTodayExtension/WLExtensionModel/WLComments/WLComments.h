//
//  WLComments.h
//  WrapLive
//
//  Created by Yura Granchenko on 12/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLArchivingObject.h"

@interface WLComments : WLArchivingObject

@property (strong, nonatomic) NSString *identifier;
@property (strong, nonatomic) NSString *contributorName;
@property (strong, nonatomic) NSString *comment;

+ (instancetype)initWithAttributes:(NSDictionary *)attributes;

@end
