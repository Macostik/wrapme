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

@implementation WLWrap (Extended)

+ (NSNumber *)uploadingOrder {
    return @1;
}

+ (instancetype)wrap {
    WLWrap* wrap = [self contribution];
    [wrap.contributor addWrap:wrap];
    [wrap save];
    return wrap;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:@"wrap_uid"];
}

- (void)awakeFromInsert {
    [super awakeFromInsert];
    self.unread = @YES;
}

- (void)remove {
    [[WLUser currentUser] removeWrap:self];
    [super remove];
    [self broadcastRemoving];
}

- (void)touch {
    [super touch];
    [[WLUser currentUser] sortWraps];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    self.name = [dictionary stringForKey:@"name"];
    if (!self.candies) {
        self.candies = [NSMutableOrderedSet orderedSet];
    }
    for (NSDictionary* date in dictionary[@"dates"]) {
        [WLCandy API_entries:[date arrayForKey:@"candies"] relatedEntry:self container:self.candies];
    }
    [self.candies sortEntries];
    
    NSMutableOrderedSet* contributors = [NSMutableOrderedSet orderedSet];
    for (NSDictionary* contributor in [dictionary arrayForKey:@"contributors"]) {
        WLUser* user = [WLUser API_entry:contributor];
        if (user) {
            [contributors addObject:user];
        }
        if ([contributor boolForKey:@"is_creator"]) {
            self.contributor = user;
        }
    }
    self.contributors = [contributors copy];
    
	WLPicture* picture = [[WLPicture alloc] init];
	picture.large = [dictionary stringForKey:@"large_cover_url"];
	picture.medium = [dictionary stringForKey:@"medium_cover_url"];
	picture.small = [dictionary stringForKey:@"small_cover_url"];
	self.picture = picture;
    return self;
}

- (void)addCandies:(NSOrderedSet *)candies {
    if (!self.candies) {
        self.candies = [NSMutableOrderedSet orderedSet];
    }
    [self.candies unionOrderedSet:candies];
    [self.candies sortEntries];
}

- (NSString *)contributorNamesWithCount:(NSInteger)numberOfUsers {
    if (self.contributors.nonempty) {
        NSMutableString* contributorNames = [NSMutableString string];
        BOOL moreUsers = self.contributors.count > numberOfUsers;
        NSInteger count = moreUsers ? numberOfUsers : self.contributors.count;
        for (NSInteger i = 0; i < count; i++) {
            WLUser* contributor = self.contributors[i];
            if (contributorNames.nonempty) {
                [contributorNames appendString:@", "];
            }
            [contributorNames appendString:[contributor isCurrentUser] ? @"You" : contributor.name];
        }
        if (moreUsers) {
            [contributorNames appendString:@"..."];
        }
        return [contributorNames copy];
    }
    return nil;
}

- (NSString *)contributorNames {
    return [self contributorNamesWithCount:4];
}

- (void)addCandy:(WLCandy *)candy {
    if (!candy || [self.candies containsObject:candy]) {
        return;
    }
    candy.wrap = self;
    if (!self.candies) {
        self.candies = [NSMutableOrderedSet orderedSet];
    }
    [self.candies addObject:candy];
    [self.candies sortEntries];
	[self touch];
    [self save];
	[self broadcastChange];
	[candy broadcastCreation];
}

- (BOOL)containsCandy:(WLCandy *)candy {
    return [candy belongsToWrap:self];
}

- (void)sortCandies {
    [self.candies sortEntries];
    [self save];
}

- (void)removeCandy:(WLCandy *)candy {
    if ([self.candies containsObject:candy]) {
        [self.candies removeObject:candy];
        [self broadcastChange];
        [candy broadcastRemoving];
    }
}

- (NSOrderedSet *)candiesOfType:(NSInteger)type maximumCount:(NSUInteger)maximumCount {
    return [NSOrderedSet orderedSetWithBlock:^(NSMutableOrderedSet *candies) {
        for (WLCandy* candy in self.candies) {
            if (type == 0 || [candy isCandyOfType:type]) {
                [candies addObject:candy];
            }
            if (maximumCount > 0 && [candies count] >= maximumCount) {
                break;
            }
        }
    }];
}

- (NSOrderedSet*)candies:(NSUInteger)maximumCount {
	return [self candiesOfType:0 maximumCount:maximumCount];
}

- (NSOrderedSet*)images:(NSUInteger)maximumCount {
	return [self candiesOfType:WLCandyTypeImage maximumCount:maximumCount];
}

- (NSOrderedSet*)messages:(NSUInteger)maximumCount {
	return [self candiesOfType:WLCandyTypeMessage maximumCount:maximumCount];
}

- (NSOrderedSet*)images {
	return [self images:0];
}

- (NSOrderedSet*)messages {
	return [self messages:0];
}

- (NSOrderedSet*)recentCandies:(NSUInteger)maximumCount {
    return [NSOrderedSet orderedSetWithBlock:^(NSMutableOrderedSet *candies) {
        __block BOOL hasMessage = NO;
        for (WLCandy* candy in self.candies) {
            if ([candies count] < maximumCount) {
                if ([candy isMessage]) {
                    if (!hasMessage) {
                        hasMessage = YES;
                        [candies addObject:candy];
                    }
                } else {
                    [candies addObject:candy];
                }
            } else {
                break;
            }
        }
    }];
}

- (void)uploadMessage:(NSString *)message success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    WLCandy* candy = [WLCandy candyWithType:WLCandyTypeMessage wrap:self];
    candy.message = message;
    [[WLUploading uploading:candy] upload:success failure:failure];
    [candy save];
}

- (void)uploadImage:(UIImage *)image success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	[[WLImageCache uploadingCache] setImage:image completion:^(NSString *path) {
		WLPicture* picture = [[WLPicture alloc] init];
		picture.large = path;
		[[WLImageCache uploadingCache] setImage:[image thumbnailImage:320] completion:^(NSString *path) {
			picture.medium = path;
			[[WLImageCache uploadingCache] setImage:[image thumbnailImage:160] completion:^(NSString *path) {
				picture.small = path;
                WLCandy* candy = [WLCandy candyWithType:WLCandyTypeImage wrap:self];
                candy.picture = picture;
                [[WLUploading uploading:candy] upload:success failure:failure];
                [candy save];
			}];
		}];
	}];
}

- (BOOL)shouldStartUploadingAutomatically {
    return YES;
}

@end



