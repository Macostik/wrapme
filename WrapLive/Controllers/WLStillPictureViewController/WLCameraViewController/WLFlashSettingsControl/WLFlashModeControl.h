//
//  WLFlashSettingsControl.h
//  WrapLive
//
//  Created by Sergey Maximenko on 23.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface WLFlashModeControl : UIControl

@property (strong, nonatomic) UIColor* titleColor;

@property (nonatomic) AVCaptureFlashMode mode;

@property (nonatomic) BOOL selecting;

- (void)setMode:(AVCaptureFlashMode)mode animated:(BOOL)animated;

- (void)setSelecting:(BOOL)selecting animated:(BOOL)animated;

@end
