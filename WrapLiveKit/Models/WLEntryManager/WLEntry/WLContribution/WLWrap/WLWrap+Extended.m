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
#import "WLCollections.h"
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
        wrap.contributors = [NSSet setWithObject:wrap.contributor];
    }
    return wrap;
}

+ (NSString *)API_identifier:(NSDictionary *)dictionary {
	return [dictionary stringForKey:WLWrapUIDKey];
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [super API_setup:dictionary relatedEntry:relatedEntry];
    NSString* name = [dictionary stringForKey:WLNameKey];
    if (!NSStringEqual(self.name, name)) self.name = name;
    
    NSArray *contributorsArray = [dictionary arrayForKey:WLContributorsKey];
    if (contributorsArray.nonempty) {
        [self addContributors:[WLUser API_entries:contributorsArray]];
    }
    
    if (dictionary[WLCreatorUIDKey] != nil) {
        WLUser *contributor = [WLUser entry:dictionary[WLCreatorUIDKey]];
        if (self.contributor != contributor) self.contributor = contributor;
    }
    
    if (![self.contributors containsObject:[WLUser currentUser]]) {
        [self addContributorsObject:[WLUser currentUser]];
    }
    
    NSSet* candies = [WLCandy API_entries:[dictionary arrayForKey:WLCandiesKey] relatedEntry:self];
    if (candies.nonempty && ![candies isSubsetOfSet:self.candies]) {
        [self addCandies:candies];
    }
    return self;
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

- (void)addCandy:(WLCandy *)candy {
    NSSet *candies = self.candies;
    if (!candy || [candies containsObject:candy]) {
        return;
    }
    __weak typeof(self)weakSelf = self;
	[candy notifyOnAddition:^(id object) {
        [weakSelf addCandiesObject:candy];
        [weakSelf touch];
    }];
}

- (BOOL)containsCandy:(WLCandy *)candy {
    return [candy belongsToWrap:self];
}

- (WLPicture *)picture {
    return [[[[self.candies allObjects] sortByUpdatedAt] firstObject] picture];
}

- (void)removeCandy:(WLCandy *)candy {
    [self removeCandiesObject:candy];
}

- (void)removeMessage:(WLMessage *)message {
    [self removeMessagesObject:message];
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
    NSSet *wraps = [self.contributor.wraps where:@"contributor == %@", [WLUser currentUser]];
    return [wraps containsObject:self] && wraps.count == 1;
}

- (NSUInteger)unreadNotificationsMessageCount {
    NSDate *date = [NSDate dayAgo];
    return [self.messages selects:^BOOL(WLMessage *message) {
        return message.unread && message.contributor && !message.contributedByCurrentUser && [message.createdAt later:date];
    }].count;
}

- (void)countOfUnreadMessages:(void (^)(NSUInteger))success failure:(WLFailureBlock)failure {
    NSDate *date = [NSDate dayAgo];
    [[WLMessage fetchRequest:@"wrap == %@ AND unread == YES AND contributor != %@ AND createdAt > %@", self, [WLUser currentUser], date] count:success failure:failure];
}

@end



