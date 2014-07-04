//
//  WLWrapEditSession.m
//  WrapLive
//
//  Created by Oleg Vishnivetskiy on 6/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrapEditSession.h"
#import "NSArray+Additions.h"
#import "WLUser+Extended.h"
#import "NSDictionary+Extended.h"

@implementation WLWrapEditSession

- (void)setName:(NSString *)name {
    [self.changed trySetObject:name forKey:@"name"];
}

- (NSString *)name {
    return [self.changed objectForKey:@"name"];
}

- (void)setUrl:(NSString *)url {
    [self.changed trySetObject:url forKey:@"url"];
}

- (NSString *)url {
    return [self.changed objectForKey:@"url"];
}

- (void)setContributors:(NSMutableOrderedSet *)contributors {
    [contributors sortUsingComparator:^NSComparisonResult(WLUser *contributor1, WLUser *contributor2) {
        if ([contributor1 isCurrentUser]) {
            return NSOrderedAscending;
        } else if ([contributor2 isCurrentUser]) {
            return NSOrderedDescending;
        } else if (![self.entry.contributors containsObject:contributor1] && ![self.entry.contributors containsObject:contributor2]) {
            return [contributor1.name compare:contributor2.name];
        } else if (![self.entry.contributors containsObject:contributor1]) {
            return NSOrderedDescending;
        } else if (![self.entry.contributors containsObject:contributor2]) {
            return NSOrderedAscending;
        } else {
            return [contributor1.name compare:contributor2.name];
        }
    }];
    [self.changed trySetObject:contributors forKey:@"contributors"];
}

- (NSMutableOrderedSet *)contributors {
    return [self.changed objectForKey:@"contributors"];
}

- (void)setInvitees:(NSArray *)invitees {
    [self.changed trySetObject:invitees forKey:@"invitees"];
}

- (NSArray *)invitees {
    return [self.changed objectForKey:@"invitees"];
}

- (void)setup:(NSMutableDictionary *)dictionary entry:(WLWrap *)wrap {
    [dictionary trySetObject:wrap.name forKey:@"name"];
    [dictionary trySetObject:[NSMutableOrderedSet orderedSetWithOrderedSet:wrap.contributors] forKey:@"contributors"];
    [dictionary trySetObject:wrap.picture.large forKey:@"url"];
}

- (BOOL)hasChanges {
    if (![self.name isEqualToString:[self.original objectForKey:@"name"]]) {
        return YES;
    } else if (![self.url isEqualToString:[self.original objectForKey:@"url"]]) {
        return YES;
    } else if (self.invitees.nonempty) {
        return YES;
    } else if ([self.contributors count] != [[self.original objectForKey:@"contributors"] count]) {
		return YES;
	} else {
        return ![self.contributors isSubsetOfOrderedSet:[self.original objectForKey:@"contributors"]];
	}
}

- (void)apply:(NSMutableDictionary *)dictionary entry:(WLWrap *)wrap {
    wrap.name = [dictionary objectForKey:@"name"];
    if (!wrap.picture) {
        wrap.picture = [[WLPicture alloc] init];
    }
    wrap.picture.large = [dictionary objectForKey:@"url"];
    wrap.contributors = [dictionary objectForKey:@"contributors"];
    wrap.invitees = [dictionary objectForKey:@"invitees"];
}

@end
