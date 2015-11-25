//
//  WLCommonEnums.h
//  meWrap
//
//  Created by Ravenpod on 12/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(int16_t, WLEvent) {
    WLEventAdd,
    WLEventUpdate,
    WLEventDelete
};

typedef NS_ENUM (NSUInteger, WLContributionStatus) {
    WLContributionStatusReady,
    WLContributionStatusInProgress,
    WLContributionStatusFinished
};

typedef NS_ENUM(NSInteger, WLStillPictureMode) {
    WLStillPictureModeDefault,
    WLStillPictureModeSquare
};

typedef NS_ENUM(int16_t, MediaType) {
    MediaTypePhoto = 10,
    MediaTypeVideo = 20,
};
