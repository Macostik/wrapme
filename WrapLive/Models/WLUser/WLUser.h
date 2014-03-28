//
//  WLUser.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"

@class WLPicture;

@interface WLUser : WLArchivingObject

@property (strong, nonatomic) NSString* phoneNumber;
@property (strong, nonatomic) NSString* countryCallingCode;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSDate* birthdate;
@property (strong, nonatomic) WLPicture* avatar;

- (BOOL)isEqualToUser:(WLUser*)user;

@end
