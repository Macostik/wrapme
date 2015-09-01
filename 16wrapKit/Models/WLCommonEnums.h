//
//  WLCommonEnums.h
//  moji
//
//  Created by Ravenpod on 12/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

typedef NS_ENUM(int16_t, WLEvent) {
    WLEventAdd,
    WLEventUpdate,
    WLEventDelete
};

typedef NS_ENUM(NSInteger, WLStillPictureMode) {
    WLStillPictureModeDefault,
    WLStillPictureModeSquare
};

static CGFloat WLStillPictureCameraViewAspectRatio = 0.75f;
static CGFloat WLStillPictureBottomViewHeight = 36.0f;
