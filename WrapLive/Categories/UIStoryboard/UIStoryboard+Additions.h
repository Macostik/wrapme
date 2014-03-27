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

@interface UIStoryboard (Additions)

- (id)homeViewController;

- (id)cameraViewController;

@end

static NSString* WLStoryboardSegueContributorsIdentifier = @"contributors";
static NSString* WLStoryboardSegueWrapIdentifier = @"wrap";

@interface UIStoryboardSegue (Additions)

- (BOOL)isContributorsSegue;

- (BOOL)isWrapSegue;

@end
