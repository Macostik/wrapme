//
//  WLCountry.h
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "JSONModel.h"

@interface WLCountry : JSONModel

@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSString* callingCode;

@end
