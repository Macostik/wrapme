//
//  WLUser.h
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLUser.h"

static NSUInteger WLProfileNameLimit = 40;
static NSUInteger WLPhoneNumberLimit = 20;

@interface WLUser (Extended)

@property (nonatomic, readonly) BOOL isSignupCompleted;

@property (nonatomic, readonly) BOOL isInvited;

@property (readonly, nonatomic) NSDate* invitedAt;

@property (readonly, nonatomic) NSString *invitationHintText;

- (void)addWrap:(WLWrap*)wrap;

- (void)removeWrap:(WLWrap*)wrap;

- (NSMutableOrderedSet*)sortedWraps;

@end

@interface WLUser (CurrentUser)

+ (WLUser*)currentUser;

+ (void)setCurrentUser:(WLUser*)user;

+ (NSString*)combinedIdentifier;

- (void)setCurrent;

- (BOOL)isCurrentUser;

@end