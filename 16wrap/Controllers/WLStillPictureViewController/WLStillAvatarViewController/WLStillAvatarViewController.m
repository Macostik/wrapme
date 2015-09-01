//
//  WLOldStillPictureViewController.m
//  moji
//
//  Created by Ravenpod on 6/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillAvatarViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLHintView.h"
#import "WLEditAvatarViewController.h"
#import "WLHomeViewController.h"
#import "WLSoundPlayer.h"
#import "WLToast.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIView+AnimationHelper.h"
#import "WLNavigationHelper.h"

@interface WLStillAvatarViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLEntryNotifyReceiver>

@property (strong, nonatomic) WLEditPicture* picture;

@end

@implementation WLStillAvatarViewController

- (void)handleImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum {
    __weak typeof(self)weakSelf = self;
    [self editImage:image completion:^ (UIImage *resultImage, NSString *comment) {
        if (saveToAlbum) [resultImage save:nil];
        weakSelf.view.userInteractionEnabled = NO;
        self.picture = [WLEditPicture picture:resultImage mode:weakSelf.mode completion:^(id object) {
            [weakSelf finishWithPictures:@[weakSelf.picture]];
            weakSelf.view.userInteractionEnabled = YES;
        }];
    }];
}

- (void)editImage:(UIImage*)image completion:(WLUploadPhotoCompletionBlock)completion {
    WLEditAvatarViewController *controller = [WLEditAvatarViewController instantiate:self.storyboard];
    controller.mode = self.mode;
    controller.image = image;
    controller.delegate = self;
    controller.completionBlock = completion;
    [self pushViewController:controller animated:NO];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)handleAsset:(ALAsset*)asset {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropAsset:asset completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage metadata:nil saveToAlbum:NO];
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

#pragma mark - WLQuickAssetsViewControllerDelegate

- (BOOL)quickAssetsViewController:(WLQuickAssetsViewController *)controller shouldSelectAsset:(ALAsset *)asset {
    [self handleAsset:asset];
    return NO;
}

@end
