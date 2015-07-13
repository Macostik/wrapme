//
//  WLContribution.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContribution.h"
#import "WLUploading+Extended.h"

typedef NS_ENUM (NSUInteger, WLContributionStatus) {
    WLContributionStatusReady,
    WLContributionStatusInProgress,
    WLContributionStatusFinished
};

static NSUInteger WLRecentContributionsDefaultLimit = 6;

@interface WLContribution (Extended)

@property (readonly, nonatomic) WLContributionStatus status;

@property (readonly, nonatomic) BOOL uploaded;

@property (readonly, nonatomic) BOOL contributedByCurrentUser;

@property (readonly, nonatomic) BOOL deletable;

+ (instancetype)contribution;

+ (NSOrderedSet*)recentContributions;

+ (NSOrderedSet *)recentContributions:(NSUInteger)limit;

+ (NSNumber*)uploadingOrder;

- (WLContributionStatus)statusOfUploadingEvent:(WLEvent)event;

- (WLContributionStatus)statusOfAnyUploadingType;

- (BOOL)canBeUploaded;

@end
