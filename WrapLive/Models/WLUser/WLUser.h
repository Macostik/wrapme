//
//  WLUser.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

@interface WLUser : WLEntry

@property (strong, nonatomic) NSString* phoneNumber;
@property (strong, nonatomic) NSString* countryCallingCode;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSDate* birthdate;
@property (nonatomic) BOOL isCreator;

- (BOOL)isEqualToUser:(WLUser*)user;

@end

@interface WLUser (CurrentUser)

+ (WLUser*)currentUser;

+ (void)setCurrentUser:(WLUser*)user;

- (void)setCurrent;

- (BOOL)isCurrentUser;

@end

@interface NSArray (WLUser)

- (NSArray*)arrayByAddingCurrentUserAndUser:(WLUser*)user;

- (NSArray*)arrayByAddingCurrentUser;

- (NSArray*)arrayByAddingUser:(WLUser*)user;

- (NSArray*)arrayByRemovingCurrentUserAndUser:(WLUser*)user;

- (NSArray*)arrayByRemovingCurrentUser;

- (NSArray*)arrayByRemovingUser:(WLUser*)user;

- (NSArray*)arrayByRemovingUsers:(NSArray*)users;

@end
