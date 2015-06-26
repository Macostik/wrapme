//
//  WLOldStillPictureViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLOldStillPictureViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLHintView.h"
#import "WLWrapView.h"
#import "WLUploadPhotoViewController.h"
#import "WLNavigationAnimator.h"
#import "WLHomeViewController.h"
#import "WLSoundPlayer.h"
#import "WLToast.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIView+AnimationHelper.h"
#import "WLAssetsGroupViewController.h"
#import "WLNavigationHelper.h"

@interface WLOldStillPictureViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLEntryNotifyReceiver, WLAssetsViewControllerDelegate>

@end

@implementation WLOldStillPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.startFromGallery) {
        [self openGallery:YES animated:NO];
    }
}

- (void)handleImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum {
    __weak typeof(self)weakSelf = self;
    [self editImage:image completion:^ (UIImage *resultImage, NSString *comment) {
        if (saveToAlbum) [resultImage save:metadata];
        weakSelf.view.userInteractionEnabled = NO;
        [WLEditPicture picture:resultImage mode:weakSelf.mode completion:^(WLEditPicture *picture) {
            picture.comment = comment;
            [weakSelf finishWithPictures:@[picture]];
            weakSelf.view.userInteractionEnabled = YES;
        }];
    }];
}

- (void)editImage:(UIImage*)image completion:(WLUploadPhotoCompletionBlock)completion {
    WLUploadPhotoViewController *controller = [WLUploadPhotoViewController instantiate:self.storyboard];
    controller.wrap = self.wrap;
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

- (void)handleAssets:(NSArray*)assets {
    __weak typeof(self)weakSelf = self;
    self.view.userInteractionEnabled = NO;
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 3;
    NSMutableArray* pictures = [NSMutableArray array];
    for (ALAsset* asset in assets) {
        runQueuedOperation(@"wl_still_picture_queue",3,^(WLOperation *operation) {
            [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                [WLEditPicture picture:croppedImage mode:weakSelf.mode completion:^(WLEditPicture *picture) {
                    [pictures addObject:picture];
                    [operation finish];
                    if (pictures.count == assets.count) {
                        weakSelf.view.userInteractionEnabled = YES;
                        [weakSelf finishWithPictures:pictures];
                    }
                }];
            }];
        });
    }
}

#pragma mark - WLAssetsViewControllerDelegate

- (void)assetsViewController:(id)controller didSelectAssets:(NSArray *)assets {
    if ([assets count] == 1) {
        [self handleAsset:[assets firstObject]];
    } else {
        self.viewControllers = @[self.topViewController];
        [self handleAssets:assets];
    }
}

@end
