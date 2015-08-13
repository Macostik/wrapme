//
//  WLFlashSettingsControl.h
//  moji
//
//  Created by Ravenpod on 23.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface WLFlashModeControl : UIControl

@property (nonatomic) AVCaptureFlashMode mode;

@property (nonatomic) BOOL selecting;

- (void)setMode:(AVCaptureFlashMode)mode animated:(BOOL)animated;

- (void)setSelecting:(BOOL)selecting animated:(BOOL)animated;

@end
