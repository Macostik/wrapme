//
//  WLWrapDay.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/27/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "JSONModel.h"

@interface WLWrapDay : JSONModel

@property (strong, nonatomic) NSArray *candies;
@property (strong, nonatomic) NSDate *modified;

@end
