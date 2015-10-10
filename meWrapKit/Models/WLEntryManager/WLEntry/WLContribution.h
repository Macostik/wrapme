//
//  WLContribution.h
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntry.h"
#import "WLCommonEnums.h"
#import "WLUploading.h"

@class WLUser;
@class WLUploading;

typedef NS_ENUM (NSUInteger, WLContributionStatus) {
    WLContributionStatusReady,
    WLContributionStatusInProgress,
    WLContributionStatusFinished
};

static NSUInteger WLRecentContributionsDefaultLimit = 6;

@interface WLContribution : WLEntry

@property (nonatomic, retain) WLUser *contributor;

@property (nonatomic, retain) WLUploading *uploading;

@property (nonatomic, retain) WLUser *editor;

@property (nonatomic, retain) NSDate *editedAt;

@property (readonly, nonatomic) WLContributionStatus status;

@property (readonly, nonatomic) BOOL uploaded;

@property (readonly, nonatomic) BOOL contributedByCurrentUser;

@property (readonly, nonatomic) BOOL deletable;

+ (NSOrderedSet*)recentContributions;

+ (NSOrderedSet *)recentContributions:(NSUInteger)limit;

- (WLContributionStatus)statusOfUploadingEvent:(WLEvent)event;

- (WLContributionStatus)statusOfAnyUploadingType;

- (BOOL)canBeUploaded;

@end
