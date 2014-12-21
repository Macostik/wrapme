//
//  WLContribution.h
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContribution.h"

typedef NS_ENUM (NSUInteger, WLContributionStatus) {
    WLContributionStatusReady,
    WLContributionStatusInProgress,
    WLContributionStatusUploaded
};

@interface WLContribution (Extended)

@property (readonly, nonatomic) WLContributionStatus status;

@property (readonly, nonatomic) BOOL uploaded;

@property (readonly, nonatomic) BOOL contributedByCurrentUser;

@property (readonly, nonatomic) BOOL deletable;

+ (instancetype)contribution;

+ (NSNumber*)uploadingOrder;

- (BOOL)shouldStartUploadingAutomatically;

- (BOOL)canBeUploaded;

@end
