//
//  WLStillPictureViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLStillPictureViewController.h"
#import "WLNavigationHelper.h"

@interface WLStillPictureViewController ()

@end

@implementation WLStillPictureViewController

@dynamic delegate;

+ (instancetype)stillPictureViewController {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if (screenSize.width == 320 && screenSize.height == 480) {
        return [self instantiateWithIdentifier:@"WLOldStillPictureViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    } else {
        return [self instantiateWithIdentifier:@"WLNewStillPictureViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    }
}

@end
