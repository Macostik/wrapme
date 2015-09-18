//
//  WLWrap.m
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWrap+Extended.h"
#import "WLEntryNotifier.h"
#import "NSString+Additions.h"
#import "WLCollections.h"
#import "WLEntryManager.h"
#import "WLImageCache.h"
#import "UIImage+Resize.h"
#import "WLEntry+WLAPIRequest.h"
#import "WLAPIResponse.h"
#import "NSDate+Additions.h"
#import "WLOperationQueue.h"
#import "WLLocalization.h"
#import "GCDHelper.h"

@implementation WLWrap (Extended)

+ (NSNumber *)uploadingOrder {
    return @1;
}

+ (instancetype)wrap {
    WLWrap* wrap = [self contribution];
    [wrap.contributor addWrap:wrap];
    if (wrap.contributor) {
        wrap.contributors = [NSSet setWithObject:wrap.contributor];
    }
    return wrap;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLWrapUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    [super API_setup:dictionary container:container];
    NSString* name = [dictionary stringForKey:WLNameKey];
    if (!NSStringEqual(self.name, name)) self.name = name;
    
    BOOL isPublic = [dictionary boolForKey:@"is_public"];
    if (self.isPublic != isPublic) self.isPublic = isPublic;
    
    BOOL isRestrictedInvite = [dictionary boolForKey:@"is_restricted_invite"];
    if (self.isRestrictedInvite != isRestrictedInvite) self.isRestrictedInvite = isRestrictedInvite;
    
    NSArray *contributorsArray = [dictionary arrayForKey:WLContributorsKey];
    if (contributorsArray.nonempty) {
        [self addContributors:[WLUser API_entries:contributorsArray]];
    }
    
    if (dictionary[WLCreatorKey] != nil) {
        WLUser *contributor = [WLUser API_entry:dictionary[WLCreatorKey]];
        if (self.contributor != contributor) self.contributor = contributor;
    } else if (dictionary[WLCreatorUIDKey] != nil) {
        WLUser *contributor = [WLUser entry:dictionary[WLCreatorUIDKey]];
        if (self.contributor != contributor) self.contributor = contributor;
    }
    
    if (self.isPublic) {
        BOOL isFollowing = [dictionary boolForKey:@"is_following"];
        if (!self.isContributing && isFollowing) [self addContributorsObject:[WLUser currentUser]];
    } else {
        if (!self.isContributing) [self addContributorsObject:[WLUser currentUser]];
    }
    
    NSSet* candies = [WLCandy API_entries:[dictionary arrayForKey:WLCandiesKey] container:self];
    if (candies.nonempty && ![candies isSubsetOfSet:self.candies]) {
        [self addCandies:candies];
    }
    
    return self;
}

- (BOOL)isContributing {
    return [self.contributors containsObject:[WLUser currentUser]];
}

- (NSString *)contributorNamesWithYouAndAmount:(NSInteger)numberOfUsers {
    NSSet *contributors = self.contributors;
    if (contributors.count <= 1 || numberOfUsers == 0) return WLLS(@"you");
    NSMutableString* names = [NSMutableString string];
    NSUInteger i = 0;
    for (WLUser *contributor in contributors) {
        if (i < numberOfUsers) {
            if (![contributor isCurrentUser]) {
                [names appendFormat:@"%@, ", contributor.name];
                ++i;
            }
        } else {
            [names appendFormat:@"%@ ...", WLLS(@"you")];
            return names;
        }
    }
    [names appendString:WLLS(@"you")];
    return names;
}

- (NSString *)contributorNames {
    return [self contributorNamesWithYouAndAmount:3];
}

- (WLPicture *)picture {
    return [self.cover picture];
}

- (BOOL)isFirstCreated {
    NSSet *wraps = [self.contributor.wraps where:@"contributor == %@", [WLUser currentUser]];
    return [wraps containsObject:self] && wraps.count == 1;
}

- (BOOL)requiresFollowing {
    return self.isPublic && !self.isContributing;
}

@end



