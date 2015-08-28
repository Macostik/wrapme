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
    return [[[[self.candies allObjects] sortByUpdatedAt] firstObject] picture];
}

- (void)uploadMessage:(NSString *)text success:(WLMessageBlock)success failure:(WLFailureBlock)failure {
	__weak WLMessage* message = [WLMessage contribution];
    __weak typeof(self)weakSelf = self;
    [message notifyOnAddition:^(id object) {
        message.contributor = [WLUser currentUser];
        message.wrap = weakSelf;
        message.text = text;
    }];
    [WLUploadingQueue upload:[WLUploading uploading:message] success:success failure:failure];
}

- (void)uploadPicture:(WLEditPicture *)picture success:(WLCandyBlock)success failure:(WLFailureBlock)failure {
    WLCandy* candy = [WLCandy candyWithType:WLCandyTypeImage wrap:self];
    candy.picture = [picture uploadablePicture:YES];
    if (picture.comment.nonempty) {
        [candy addCommentsObject:[WLComment comment:picture.comment]];
    }
    __weak typeof(self)weakSelf = self;
    [candy notifyOnAddition:^(id object) {
        [weakSelf addCandiesObject:candy];
        [weakSelf touch];
    }];
    [WLUploadingQueue upload:[WLUploading uploading:candy] success:success failure:failure];
}

- (void)uploadPicture:(WLPicture *)picture {
    [self uploadPicture:picture success:^(WLCandy *candy) { } failure:^(NSError *error) { }];
}

- (void)uploadPictures:(NSArray *)pictures start:(WLBlock)start finish:(WLBlock)finish {
    __weak typeof(self)weakSelf = self;
    for (WLPicture *picture in pictures) {
        runUnaryQueuedOperation(@"wl_upload_candies_queue", ^(WLOperation *operation) {
            [weakSelf uploadPicture:picture];
            if (start) start();
            run_after(0.6f, ^{
                if (finish) finish();
                [operation finish];
            });
        });
    }
}

- (void)uploadPictures:(NSArray *)pictures {
    [self uploadPictures:pictures start:nil finish:nil];
}

- (BOOL)isFirstCreated {
    NSSet *wraps = [self.contributor.wraps where:@"contributor == %@", [WLUser currentUser]];
    return [wraps containsObject:self] && wraps.count == 1;
}

- (BOOL)requiresFollowing {
    return self.isPublic && !self.isContributing;
}

@end



