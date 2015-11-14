//
//  WLOldStillPictureViewController.m
//  meWrap
//
//  Created by Ravenpod on 6/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStillAvatarViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLHintView.h"
#import "WLEditAvatarViewController.h"
#import "WLHomeViewController.h"
#import "WLToast.h"

@interface WLStillAvatarViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) MutableAsset *picture;

@end

@implementation WLStillAvatarViewController

- (void)handleImage:(UIImage*)image saveToAlbum:(BOOL)saveToAlbum {
    __weak typeof(self)weakSelf = self;
    [self editImage:image completion:^ (UIImage *resultImage, NSString *comment) {
        weakSelf.view.userInteractionEnabled = NO;
        MutableAsset *asset = [[MutableAsset alloc] init];
        asset.mode = weakSelf.mode;
        weakSelf.picture = asset;
        [asset setImage:resultImage completion:^(MutableAsset * asset) {
            if (saveToAlbum) [asset saveToAssets];
            [weakSelf finishWithPictures:@[asset]];
            weakSelf.view.userInteractionEnabled = YES;
        }];
    }];
}

- (void)editImage:(UIImage*)image completion:(WLUploadPhotoCompletionBlock)completion {
    WLEditAvatarViewController *controller = self.storyboard[@"WLEditAvatarViewController"];
    controller.mode = self.mode;
    controller.image = image;
    controller.delegate = self;
    controller.completionBlock = completion;
    [self pushViewController:controller animated:NO];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)handleAsset:(PHAsset*)asset {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropAsset:asset completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage saveToAlbum:NO];
        weakSelf.view.userInteractionEnabled = YES;
    }];
}

#pragma mark - WLQuickAssetsViewControllerDelegate

- (BOOL)quickAssetsViewController:(WLQuickAssetsViewController *)controller shouldSelectAsset:(PHAsset *)asset {
    [self handleAsset:asset];
    return NO;
}

@end
