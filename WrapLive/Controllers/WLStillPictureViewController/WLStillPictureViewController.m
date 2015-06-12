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

@synthesize wrap = _wrap;

@synthesize wrapView = _wrapView;

@synthesize mode = _mode;

+ (instancetype)stillPictureViewController {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    if (screenSize.width == 320 && screenSize.height == 480) {
        return [self instantiateWithIdentifier:@"WLStillPictureViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    } else {
        return [self instantiateWithIdentifier:@"WLNewStillPictureViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    }
}

- (void)showWrapPickerWithController:(BOOL)animated {
    if ([self.delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
        [self.delegate stillPictureViewController:self didSelectWrap:self.wrap];
    }
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    for (id <WLStillPictureBaseViewController> controller in self.viewControllers) {
        if ([controller conformsToProtocol:@protocol(WLStillPictureBaseViewController)]) {
            controller.wrap = wrap;
        }
    }
}

- (void)setupWrapView:(WLWrap *)wrap {
    
}

- (void)stillPictureViewController:(WLStillPictureBaseViewController *)controller didSelectWrap:(WLWrap *)wrap {
    [self selectWrap:nil];
}

- (IBAction)selectWrap:(UIButton *)sender {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
            [self.delegate stillPictureViewController:self didSelectWrap:self.wrap];
        }
    } else if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

@end
