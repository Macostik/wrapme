//
//  WLUser.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLUser.h"

static NSUInteger WLProfileNameLimit = 40;
static NSUInteger WLPhoneNumberLimit = 15;

@interface WLUser (Extended)

- (void)addWrap:(WLWrap*)wrap;
- (void)addWraps:(NSOrderedSet*)wraps;
- (void)removeWrap:(WLWrap*)wrap;
- (void)sortWraps;

@end

@interface WLUser (CurrentUser)

+ (WLUser*)currentUser;

+ (void)setCurrentUser:(WLUser*)user;

- (void)setCurrent;

- (BOOL)isCurrentUser;

@end

@interface NSOrderedSet (WLUser)

- (NSOrderedSet*)usersByAddingCurrentUserAndUser:(WLUser*)user;

- (NSOrderedSet*)usersByAddingCurrentUser;

- (NSOrderedSet *)usersByAddingUser:(WLUser *)user;

- (NSOrderedSet *)usersByRemovingCurrentUserAndUser:(WLUser *)user;

- (NSOrderedSet*)usersByRemovingCurrentUser;

@end