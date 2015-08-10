//
//  PGFocusAnimationView.h
//  moji
//
//  Created by Nikolay Rybalko on 7/10/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WLCameraAdjustmentType) {
    WLCameraAdjustmentTypeCombined,
    WLCameraAdjustmentTypeFocus,
    WLCameraAdjustmentTypeExposure
};

@interface WLCameraAdjustmentView : UIView

@property (nonatomic) WLCameraAdjustmentType type;

@end
