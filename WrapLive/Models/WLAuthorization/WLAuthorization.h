//
//  WLAuthorization.h
//  WrapLive
//
//  Created by Sergey Maximenko on 21.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLArchivingObject.h"

@interface WLAuthorization : WLArchivingObject

@property (strong, nonatomic) NSString *deviceUID;

@property (strong, nonatomic) NSString *deviceName;

@property (strong, nonatomic) NSString *countryCode;

@property (strong, nonatomic) NSString *phone;

@property (strong, nonatomic) NSString *formattedPhone;

@property (strong, nonatomic) NSString *email;

@property (strong, nonatomic) NSString *unconfirmed_email;

@property (strong, nonatomic) NSString *activationCode;

@property (strong, nonatomic) NSString *password;

- (NSString*)fullPhoneNumber;

- (BOOL)canAuthorize;

- (void)updateWithUserData:(NSDictionary*)userData;

@end

@interface WLAuthorization (CurrentAuthorization)

+ (WLAuthorization*)currentAuthorization;

+ (void)setCurrentAuthorization:(WLAuthorization*)authorization;

+ (NSString *)priorityEmail;

- (void)setCurrent;

@end
