//
//  UIStoryboard+Additions.h
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* WLStoryboardWelcomeViewControllerIdentifier = @"welcome";
static NSString* WLStoryboardHomeViewControllerIdentifier = @"home";
static NSString* WLStoryboardCameraViewControllerIdentifier = @"camera";
static NSString* WLStoryboardWrapViewControllerIdentifier = @"wrap";
static NSString* WLStoryboardSignUpViewControllerIdentifier = @"signUp";
static NSString* WLStoryboardCandyViewControllerIdentifier = @"candy";
static NSString* WLStoryboardChatViewControllerIdentifier = @"chat";
static NSString* WLStoryboardImageViewControllerIdentifier = @"image";
static NSString* WLStoryboardEditWrapViewControllerIdentifier = @"editWrap";

@interface UIStoryboard (Additions)

- (id)welcomeViewController;

- (id)homeViewController;

- (id)cameraViewController;

- (id)wrapViewController;

- (id)signUpViewController;

- (id)candyViewController;

- (id)chatViewController;

- (id)editWrapViewController;

@end

static NSString* WLStoryboardSegueContributorsIdentifier = @"contributors";
static NSString* WLStoryboardSegueCameraIdentifier = @"camera";
static NSString* WLStoryboardSegueChangeWrapIdentifier = @"changeWrap";
static NSString* WLStoryboardSegueImageIdentifier = @"image";

@interface UIStoryboardSegue (Additions)

- (BOOL)isContributorsSegue;

- (BOOL)isCameraSegue;

- (BOOL)isChangeWrapSegue;

- (BOOL)isImageSegue;

@end
