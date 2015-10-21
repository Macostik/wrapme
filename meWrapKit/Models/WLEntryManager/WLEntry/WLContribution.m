//
//  WLContribution.m
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContribution.h"
#import "WLUser.h"


@implementation WLContribution

@dynamic contributor;
@dynamic uploading;
@dynamic editor;
@dynamic editedAt;

+ (NSOrderedSet *)recentContributions {
    NSMutableArray *contributions = [NSMutableArray array];
    NSDate *date = [[NSDate now] beginOfDay];
    [contributions adds:[WLComment entriesWhere:@"createdAt > %@ AND contributor != nil", date]];
    [contributions adds:[WLCandy entriesWhere:@"createdAt > %@ AND contributor != nil", date]];
    [contributions sortByCreatedAt];
    return [contributions orderedSet];
}

+ (NSOrderedSet *)recentContributions:(NSUInteger)limit {
    NSOrderedSet *contributions = [self recentContributions];
    if (contributions.count > limit) {
        return [NSOrderedSet orderedSetWithArray:[[contributions array] subarrayWithRange:NSMakeRange(0, limit)]];
    }
    return contributions;
}

- (WLContributionStatus)status {
    return [self statusOfUploadingEvent:WLEventAdd];
}

- (WLContributionStatus)statusOfUploadingEvent:(WLEvent)event {
    WLUploading* uploading = self.uploading;
    if (!uploading || uploading.type != event) {
        return WLContributionStatusFinished;
    } else if (uploading.inProgress) {
        return WLContributionStatusInProgress;
    } else {
        return WLContributionStatusReady;
    }
}

- (WLContributionStatus)statusOfAnyUploadingType {
    WLUploading* uploading = self.uploading;
    if (!uploading) {
        return WLContributionStatusFinished;
    } else if (uploading.inProgress) {
        return WLContributionStatusInProgress;
    } else {
        return WLContributionStatusReady;
    }
}

- (BOOL)uploaded {
    return self.status == WLContributionStatusFinished;
}

- (BOOL)contributedByCurrentUser {
    return [self.contributor current];
}

- (BOOL)deletable {
    return self.contributedByCurrentUser;
}

- (BOOL)canBeUploaded {
    return YES;
}

@end
