//
//  WLUser.h
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntry.h"

static NSInteger WLProfileNameLimit = 40;

@interface WLUser : WLEntry

@property (strong, nonatomic) NSString* phoneNumber;
@property (strong, nonatomic) NSString* countryCallingCode;
@property (strong, nonatomic) NSString* name;
@property (strong, nonatomic) NSDate* birthdate;
@property (nonatomic) BOOL isCreator;

@end

@interface WLUser (CurrentUser)

+ (WLUser*)currentUser;

+ (void)setCurrentUser:(WLUser*)user;

- (void)setCurrent;

- (BOOL)isCurrentUser;

@end

@interface NSArray (WLUser)

- (NSArray*)usersByAddingCurrentUserAndUser:(WLUser*)user;

- (NSArray*)usersByAddingCurrentUser;

- (NSArray*)usersByAddingUser:(WLUser*)user;

- (NSArray*)usersByRemovingCurrentUserAndUser:(WLUser*)user;

- (NSArray*)usersByRemovingCurrentUser;

- (NSArray*)usersByRemovingUser:(WLUser*)user;

- (NSArray*)usersByRemovingUsers:(NSArray*)users;

@end
