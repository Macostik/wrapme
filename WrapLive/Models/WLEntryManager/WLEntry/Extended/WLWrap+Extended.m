//
//  WLWrap.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap+Extended.h"
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"
#import "NSOrderedSet+Additions.h"
#import "WLEntryManager.h"
#import "WLImageCache.h"
#import "UIImage+Resize.h"
#import "WLAPIManager.h"
#import "WLAPIResponse.h"
#import "WLInternetConnectionBroadcaster.h"
#import "NSDate+Additions.h"
#import "WLSupportFunctions.h"

@implementation WLWrap (Extended)

+ (NSNumber *)uploadingOrder {
    return @1;
}

+ (instancetype)wrap {
    WLWrap* wrap = [self contribution];
    [wrap.contributor addWrap:wrap];
    if (wrap.contributor) {
        wrap.contributors = [NSMutableOrderedSet orderedSetWithObject:wrap.contributor];
    }
    return wrap;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLWrapUIDKey];
}

- (void)remove {
    [[WLUser currentUser] removeWrap:self];
    [super remove];
    [self broadcastRemoving];
}

- (void)touch:(NSDate *)date {
    [super touch:date];
    [[WLUser currentUser] sortWraps];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    NSString* name = [dictionary stringForKey:WLNameKey];
    if (!NSStringEqual(self.name, name)) self.name = name;
    if (!self.candies) self.candies = [NSMutableOrderedSet orderedSet];
    NSArray* contributorsArray = [dictionary arrayForKey:WLContributorsKey];
    NSMutableOrderedSet* contributors = [NSMutableOrderedSet orderedSetWithCapacity:[contributorsArray count]];
    for (NSDictionary* contributor in contributorsArray) {
        WLUser* user = [WLUser API_entry:contributor];
        if (user) {
            [contributors addObject:user comparator:comparatorByUserNameAscending];
        }
        if ([contributor boolForKey:WLIsCreatorKey] && self.contributor != user) {
            self.contributor = user;
        }
    }
    
    if (contributors.count != self.contributors.count || ![contributors isSubsetOfOrderedSet:self.contributors]) {
        self.contributors = contributors;
    }
    NSArray* candiesArray = [dictionary arrayForKey:WLCandiesKey];
    NSMutableOrderedSet* candies = [WLCandy API_entries:candiesArray relatedEntry:self container:[NSMutableOrderedSet orderedSetWithCapacity:[candiesArray count]]];
    if (candies.nonempty && ![candies isSubsetOfOrderedSet:self.candies]) {
        [self addCandies:candies];
    }
    return self;
}

- (void)addCandies:(NSOrderedSet *)candies {
    if (!self.candies) self.candies = [NSMutableOrderedSet orderedSetWithCapacity:[candies count]];
    [self.candies unionOrderedSet:candies];
    [self.candies sortByUpdatedAtDescending];
}

- (NSString *)contributorNamesWithCount:(NSInteger)numberOfUsers {
    NSMutableOrderedSet *contributors = self.contributors;
    if (contributors.count <= 1) return @"You";
    NSMutableString* names = [NSMutableString string];
    NSUInteger i = 0;
    for (WLUser *contributor in contributors) {
        if (i <= numberOfUsers) {
            if (![contributor isCurrentUser]) {
                [names appendFormat:@"%@, ", contributor.name];
                ++i;
            }
        } else {
            [names appendString:@"You ..."];
            return names;
        }
    }
    [names appendString:@"You"];
    return names;
}

- (NSString *)contributorNames {
    return [self contributorNamesWithCount:4];
}

- (void)addCandy:(WLCandy *)candy {
    if (!candy || [self.candies containsObject:candy]) {
        [self.candies sortByUpdatedAtDescending];
        return;
    }
    candy.wrap = self;
    if (!self.candies) self.candies = [NSMutableOrderedSet orderedSet];
    [self.candies addObject:candy comparator:comparatorByCreatedAtDescending];
	[self touch];
	[candy broadcastCreation];
}

- (BOOL)containsCandy:(WLCandy *)candy {
    return [candy belongsToWrap:self];
}

- (WLPicture *)picture {
    return [[self.candies firstObject] picture];
}

- (void)sortCandies {
    [self.candies sortByUpdatedAtDescending];
}

- (void)removeCandy:(WLCandy *)candy {
    if ([self.candies containsObject:candy]) {
        [self.candies removeObject:candy];
    }
}

- (NSOrderedSet *)candies:(NSInteger)type limit:(NSUInteger)limit {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"type == %d", type];
    NSMutableOrderedSet *candies = [[self.candies filteredOrderedSetUsingPredicate:predicate] mutableCopy];
    if (candies.count > limit) {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, limit)];
        return [NSMutableOrderedSet orderedSetWithArray:[candies objectsAtIndexes:indexes]];
    } else {
        return candies;
    }
}

- (NSMutableOrderedSet*)candies:(NSUInteger)limit {
    NSMutableOrderedSet *candies = self.candies;
    if (candies.count > limit) {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, limit)];
        return [NSMutableOrderedSet orderedSetWithArray:[candies objectsAtIndexes:indexes]];
    } else {
        return candies;
    }
}

- (NSOrderedSet*)messages:(NSUInteger)limit {
	NSMutableOrderedSet *messages = self.messages;
    if (messages.count > limit) {
        NSIndexSet* indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, limit)];
        return [NSMutableOrderedSet orderedSetWithArray:[messages objectsAtIndexes:indexes]];
    } else {
        return messages;
    }
}

- (NSMutableOrderedSet*)recentCandies:(NSUInteger)limit {
    NSMutableOrderedSet* candies = [self candies:limit];
    [candies sortByUpdatedAtDescending];
    return candies;
}

- (void)uploadMessage:(NSString *)text success:(WLMessageBlock)success failure:(WLFailureBlock)failure {
	
	if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
		failure([NSError errorWithDescription:@"Internet connection is not reachable."]);
		return;
	}
	
	__weak WLMessage* message = [WLMessage entry];
    message.contributor = [WLUser currentUser];
    message.wrap = self;
	message.text = text;
    [message broadcastCreation];
	[message add:success failure:^(NSError *error) {
		[message remove];
        failure(error);
	}];
}

- (void)uploadPicture:(WLPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    WLCandy* candy = [WLCandy candyWithType:WLCandyTypeImage wrap:self];
    candy.picture = picture;
    [[WLUploading uploading:candy] upload:success failure:failure];
}

- (void)uploadPicture:(WLPicture *)picture {
    [self uploadPicture:picture success:^(WLCandy *candy) { } failure:^(NSError *error) { }];
}

- (void)uploadPictures:(NSArray *)pictures {
    NSUInteger count = [pictures count];
    NSTimeInterval time = count/2.0f;
    __weak typeof(self)weakSelf = self;
    [pictures enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSTimeInterval delay = time*((CGFloat)idx/(CGFloat)(count - 1));
        [weakSelf performSelector:@selector(uploadPicture:) withObject:obj afterDelay:delay];
    }];
}

- (void)uploadImage:(UIImage *)image success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    __weak typeof(self)weakSelf = self;
    [WLPicture picture:image completion:^(id object) {
        [weakSelf uploadPicture:object success:success failure:failure];
    }];
}

- (BOOL)shouldStartUploadingAutomatically {
    return YES;
}

@end



