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

- (void)touch:(NSDate *)date {
    [super touch:date];
    [[WLUser currentUser] sortWraps];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    self.name = [dictionary stringForKey:@"name"];
    if (!self.candies) {
        self.candies = [NSMutableOrderedSet orderedSet];
    }
    
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
    self.contributors = contributors;
    
	WLPicture* picture = [[WLPicture alloc] init];
	picture.large = [dictionary stringForKey:@"large_cover_url"];
	picture.medium = [dictionary stringForKey:@"medium_cover_url"];
	picture.small = [dictionary stringForKey:@"small_cover_url"];
	self.picture = picture;
    return self;
}

- (NSMutableOrderedSet*)candiesFromResponse:(NSDictionary*)dictionary {
    NSMutableOrderedSet* candies = [NSMutableOrderedSet orderedSet];
    for (NSDictionary* date in dictionary[@"dates"]) {
        [WLCandy API_entries:[date arrayForKey:@"candies"] relatedEntry:self container:candies];
    }
    return candies;
}

- (void)addCandies:(NSOrderedSet *)candies {
    if (!self.candies) {
        self.candies = [NSMutableOrderedSet orderedSet];
    }
    [self.candies unionOrderedSet:candies];
    [self.candies sortByUpdatedAtDescending];
}

- (NSString *)contributorNamesWithCount:(NSInteger)numberOfUsers {
    if (self.contributors.nonempty) {
        if (self.contributors.count == 1) {
            return @"You";
        }
        NSMutableArray *contributorsArray = @[].mutableCopy;
        __block int i = 1;
        [self.contributors all:^(WLUser *contributor) {
            if (![contributor isCurrentUser] && i <= numberOfUsers) {
                [contributorsArray addObject:contributor.name.nonempty ? contributor.name : contributor.phone];
                i++;
            }
        }];
        [contributorsArray sortUsingComparator:^NSComparisonResult(NSString * user1, NSString *user2) {
            return [user1 compare:user2 options:NSCaseInsensitiveSearch];
        }];
        [contributorsArray insertObject:(self.contributors.count > numberOfUsers + 1) ? @"You ..." : @"You"
                                atIndex:contributorsArray.count];
        return [contributorsArray componentsJoinedByString:@", "];
    }
    return nil;
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
    if (!self.candies) {
        self.candies = [NSMutableOrderedSet orderedSet];
    }
    [self.candies addObject:candy];
    [self.candies sortByUpdatedAtDescending];
	[self touch];
    [self save];
	[candy broadcastCreation];
}

- (BOOL)containsCandy:(WLCandy *)candy {
    return [candy belongsToWrap:self];
}

- (void)sortCandies {
    [self.candies sortByUpdatedAtDescending];
    [self save];
}

- (void)removeCandy:(WLCandy *)candy {
    if ([self.candies containsObject:candy]) {
        [self.candies removeObject:candy];
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

- (NSMutableOrderedSet*)recentCandies:(NSUInteger)maximumCount {
    NSMutableOrderedSet* candies = [NSMutableOrderedSet orderedSet];
    for (WLCandy* candy in self.candies) {
        if ([candies count] < maximumCount) {
            if ([candy isImage]) {
                [candies addObject:candy];
            }
        } else {
            break;
        }
    }
    return candies;
}

- (void)uploadMessage:(NSString *)message success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
	
	if (![WLInternetConnectionBroadcaster broadcaster].reachable) {
		failure([NSError errorWithDescription:@"Internet connection is not reachable."]);
		return;
	}
	
	__weak WLCandy* candy = [WLCandy candyWithType:WLCandyTypeMessage wrap:self];
	candy.message = message;
	[candy add:success failure:^(NSError *error) {
		[candy remove];
        failure(error);
	}];
//	[[WLUploading uploading:candy] upload:success failure:failure];
	[candy save];
	
}

- (void)uploadPicture:(WLPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    WLCandy* candy = [WLCandy candyWithType:WLCandyTypeImage wrap:self];
    candy.picture = picture;
    [[WLUploading uploading:candy] upload:success failure:failure];
    [candy save];
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



