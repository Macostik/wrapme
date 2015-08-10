//
//  PGCameraInteractionView.h
//  moji
//
//  Created by Ravenpod on 13.02.14.
//  Copyright (c) 2014 yo, gg. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLCameraInteractionView;

@protocol WLCameraInteractionViewDelegate <NSObject>

- (void)cameraInteractionView:(WLCameraInteractionView*)view didChangeFocus:(CGPoint)focus;
- (void)cameraInteractionView:(WLCameraInteractionView*)view didChangeExposure:(CGPoint)exposure;

@end

@interface WLCameraInteractionView : UIView

@property (nonatomic, weak) IBOutlet id <WLCameraInteractionViewDelegate> delegate;

- (void)hideViews;

@end
