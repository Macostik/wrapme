//
//  UIStoryboard+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* WLStoryboardHomeViewControllerIdentifier = @"home";
static NSString* WLStoryboardCameraViewControllerIdentifier = @"camera";
static NSString* WLStoryboardWrapViewControllerIdentifier = @"wrap";
static NSString* WLStoryboardSignUpViewControllerIdentifier = @"signUp";
static NSString* WLStoryboardWrapDataViewControllerIdentifier = @"wrapData";

@interface UIStoryboard (Additions)

- (id)homeViewController;

- (id)cameraViewController;

- (id)wrapViewController;

- (id)signUpViewController;

- (id)wrapDataViewController;

@end

static NSString* WLStoryboardSegueContributorsIdentifier = @"contributors";
static NSString* WLStoryboardSegueWrapIdentifier = @"wrap";
static NSString* WLStoryboardSegueCameraIdentifier = @"camera";
static NSString* WLStoryboardSegueTopWrapIdentifier= @"topWrap";

@interface UIStoryboardSegue (Additions)

- (BOOL)isContributorsSegue;

- (BOOL)isWrapSegue;

- (BOOL)isCameraSegue;

- (BOOL)isTopWrapSegue;

@end
