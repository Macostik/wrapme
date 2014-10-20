//
//  WLProfileEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSDictionary+Extended.h"
#import "WLAuthorization.h"
#import "WLProfileEditSession.h"
#import "WlUser.h"
@implementation WLProfileEditSession

- (void)setName:(NSString *)name {
    [self setValue:name forProperty:@"name"];
}

- (NSString *)name {
    return [self valueForProperty:@"name"];
}

- (void)setEmail:(NSString *)email {
    [self setValue:email forProperty:@"email"];
}

- (NSString *)email {
    return [self valueForProperty:@"email"];
}

- (void)setUrl:(NSString *)url {
    [self setValue:url forProperty:@"url"];
}

- (NSString *)url {
    return [self valueForProperty:@"url"];
}

- (void)setup:(NSMutableDictionary *)dictionary {
    WLUser *user = (WLUser *)_entry;
    [dictionary trySetObject:user.name forKey:@"name"];
    [dictionary trySetObject:[WLAuthorization priorityEmail] forKey:@"email"];
    [dictionary trySetObject:user.picture.large forKey:@"url"];
}

- (BOOL)hasChangedName {
    return [self isPropertyChanged:@"name"];
}

- (BOOL)hasChangedEmail {
    return [self isPropertyChanged:@"email"];
}

- (BOOL)hasChangedUrl {
    return [self isPropertyChanged:@"url"];
}

- (BOOL)hasChanges {
    if ([self hasChangedName]) {
        return YES;
    } else if ([self hasChangedEmail]) {
        return YES;
    } else if ([self hasChangedUrl]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)apply:(NSMutableDictionary *)dictionary {
    WLUser *user = (WLUser *)_entry;
    user.name = [dictionary objectForKey:@"name"];
    user.picture.large = [dictionary objectForKey:@"url"];
}

@end
