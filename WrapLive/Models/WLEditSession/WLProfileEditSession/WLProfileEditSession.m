//
//  WLProfileEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLProfileEditSession.h"
#import "WlUser.h"
#import "NSDictionary+Extended.h"
#import "WLAuthorization.h"

@implementation WLProfileEditSession

- (void)setName:(NSString *)name {
    [self.changed trySetObject:name forKey:@"name"];
}

- (NSString *)name {
    return [self.changed objectForKey:@"name"];
}

- (void)setEmail:(NSString *)email {
    [self.changed trySetObject:email forKey:@"email"];
}

- (NSString *)email {
    return [self.changed objectForKey:@"email"];
}

- (void)setUrl:(NSString *)url {
    [self.changed trySetObject:url forKey:@"url"];
}

- (NSString *)url {
    return [self.changed objectForKey:@"url"];
}

- (void)setup:(NSMutableDictionary *)dictionary entry:(WLUser *)user {
    [dictionary trySetObject:user.name forKey:@"name"];
    [dictionary trySetObject:[[WLAuthorization currentAuthorization] email] forKey:@"email"];
    [dictionary trySetObject:user.picture.large forKey:@"url"];
}

- (BOOL)hasChanges {
    if (![self.name isEqualToString:[self.original objectForKey:@"name"]]) {
        return YES;
    } else if (![self.email isEqualToString:[self.original objectForKey:@"email"]]) {
        return YES;
    } else if (![self.url isEqualToString:[self.original objectForKey:@"url"]]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)apply:(NSMutableDictionary *)dictionary entry:(WLUser *)user {
    user.name = [dictionary objectForKey:@"name"];
    user.picture.large = [dictionary objectForKey:@"url"];
}

@end
