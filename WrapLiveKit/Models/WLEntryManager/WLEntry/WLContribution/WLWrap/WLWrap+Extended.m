//
//  WLWrap.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrap+Extended.h"
#import "WLEntryNotifier.h"
#import "NSString+Additions.h"
#import "NSOrderedSet+Additions.h"
#import "WLEntryManager.h"
#import "WLImageCache.h"
#import "UIImage+Resize.h"
#import "WLAPIManager.h"
#import "WLAPIResponse.h"
#import "WLNetwork.h"
#import "NSDate+Additions.h"
#import "WLUploadingQueue.h"
#import "WLOperationQueue.h"
#import "WLEditPicture.h"

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

- (void)prepareForDeletion {
    [[WLUser currentUser] removeWrap:self];
    [super prepareForDeletion];
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
    
    NSArray *contributorsArray = [dictionary arrayForKey:WLContributorsKey];
    NSMutableOrderedSet* contributors = self.contributors;
    if (contributorsArray.nonempty) {
        
        if (!contributors) {
            contributors = [NSMutableOrderedSet orderedSetWithCapacity:[contributorsArray count]];
        }
        [WLUser API_entries:contributorsArray relatedEntry:nil container:contributors];
        self.contributors = contributors;
    }
    
    if (dictionary[WLCreatorUIDKey] != nil) {
        WLUser *contributor = [WLUser entry:dictionary[WLCreatorUIDKey]];
        if (self.contributor != contributor) self.contributor = contributor;
    }
    
    if (![contributors containsObject:[WLUser currentUser]]) {
        [contributors addObject:[WLUser currentUser]];
        self.contributors = contributors;
    }
    
    NSMutableOrderedSet* candies = [WLCandy API_entries:[dictionary arrayForKey:WLCandiesKey] relatedEntry:self];
    if (candies.nonempty && ![candies isSubsetOfOrderedSet:self.candies]) {
        [self addCandies:candies];
    }
    return self;
}

- (void)addCandies:(NSOrderedSet *)candies {
    NSMutableOrderedSet *existingCandies = self.candies;
    if (!existingCandies) {
        existingCandies = [NSMutableOrderedSet orderedSetWithCapacity:[candies count]];
        self.candies = existingCandies;
    }
    [existingCandies unionOrderedSet:candies];
    if ([existingCandies sortByUpdatedAt]) {
        self.candies = existingCandies;
    }
}

- (NSString *)contributorNamesWithYouAndAmount:(NSInteger)numberOfUsers {
    NSMutableOrderedSet *contributors = self.contributors;
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

- (void)addCandy:(WLCandy *)candy {
    NSMutableOrderedSet *candies = self.candies;
    if (!candy || [candies containsObject:candy]) {
        if ([candies sortByUpdatedAt]) {
            self.candies = candies;
        }
        return;
    }
    candy.wrap = self;
    if (!candies) {
        candies = [NSMutableOrderedSet orderedSet];
        self.candies = candies;
    }
    
    __weak typeof(self)weakSelf = self;
	[candy notifyOnAddition:^(id object) {
        [candies addObject:candy comparator:comparatorByCreatedAt descending:YES];
        [weakSelf touch];
    }];
}

- (BOOL)containsCandy:(WLCandy *)candy {
    return [candy belongsToWrap:self];
}

- (WLPicture *)picture {
    return [[self.candies firstObject] picture];
}

- (void)sortCandies {
    NSMutableOrderedSet* candies = self.candies;
    if ([candies sortByUpdatedAt]) {
        self.candies = candies;
    }
}

- (void)removeCandy:(WLCandy *)candy {
    NSMutableOrderedSet *candies = self.candies;
    if ([candies containsObject:candy]) {
        [candies removeObject:candy];
        self.candies = candies;
    }
}

- (void)removeMessage:(WLMessage *)message {
    NSMutableOrderedSet *messages = self.messages;
    if ([messages containsObject:message]) {
        [messages removeObject:message];
        self.messages = messages;
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
    [candies sortByUpdatedAt];
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
    return [self candies:limit];
}

- (id)uploadMessage:(NSString *)text success:(WLMessageBlock)success failure:(WLFailureBlock)failure {
	__weak WLMessage* message = [WLMessage contribution];
    __weak typeof(self)weakSelf = self;
    [message notifyOnAddition:^(id object) {
        message.contributor = [WLUser currentUser];
        message.wrap = weakSelf;
        message.text = text;
    }];
    [WLUploadingQueue upload:[WLUploading uploading:message] success:success failure:failure];
    return message;
}

- (void)uploadPicture:(WLEditPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    WLCandy* candy = [WLCandy candyWithType:WLCandyTypeImage wrap:self];
    candy.picture = [picture uploadablePictureWithAnimation:YES];
    if (picture.comment.nonempty) {
        WLComment *comment = [WLComment comment:picture.comment];
        [candy addComment:comment];
    }
    [WLUploadingQueue upload:[WLUploading uploading:candy] success:success failure:failure];
}

- (void)uploadPicture:(WLPicture *)picture {
    [self uploadPicture:picture success:^(WLCandy *candy) { } failure:^(NSError *error) { }];
}

- (void)uploadPictures:(NSArray *)pictures {
    __weak typeof(self)weakSelf = self;
    for (WLPicture *picture in pictures) {
        runUnaryQueuedOperation(@"wl_upload_candies_queue", ^(WLOperation *operation) {
            [weakSelf uploadPicture:picture];
            run_after(0.6f, ^{
                [operation finish];
            });
        });
    }
}

- (BOOL)isFirstCreated {
    NSOrderedSet *wraps = [self.contributor.wraps objectsWhere:@"isDefault != YES AND contributor == %@", [WLUser currentUser]];
    return [wraps containsObject:self] && wraps.count == 1;
}

@end



