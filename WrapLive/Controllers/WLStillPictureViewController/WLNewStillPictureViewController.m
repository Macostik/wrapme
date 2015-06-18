//
//  WLNewStillPictureViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/9/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLNewStillPictureViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLHintView.h"
#import "WLWrapView.h"
#import "WLNavigationAnimator.h"
#import "WLSoundPlayer.h"
#import "WLToast.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIView+AnimationHelper.h"
#import "WLAssetsGroupViewController.h"
#import "WLNavigationHelper.h"
#import "UIButton+Additions.h"
#import "WLBatchEditPictureViewController.h"

@interface WLNewStillPictureViewController () <WLCameraViewControllerDelegate, UINavigationControllerDelegate, WLEntryNotifyReceiver, WLAssetsViewControllerDelegate, WLBatchEditPictureViewControllerDelegate>

@property (strong, nonatomic) NSMutableArray* pictures;

@end

@implementation WLNewStillPictureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pictures = [NSMutableArray array];
    [self updatePicturesCountLabel];
}

- (void)handleImage:(UIImage *)image metadata:(NSMutableDictionary *)metadata saveToAlbum:(BOOL)saveToAlbum {
    __weak typeof(self)weakSelf = self;
    self.view.userInteractionEnabled = NO;
    WLEditPicture *picture = [WLEditPicture picture:image mode:self.mode completion:^(WLEditPicture *picture) {
        weakSelf.view.userInteractionEnabled = YES;
    }];
    [weakSelf.pictures addObject:picture];
    [weakSelf updatePicturesCountLabel];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidFinish:(WLCameraViewController *)controller sender:(WLButton*)sender {
    WLOperationQueue *queue = [WLOperationQueue queueNamed:@"wl_still_picture_queue" capacity:3];
    
    __weak typeof(self)weakSelf = self;
    WLBlock completionBlock = ^ {
        queue.finishQueueBlock = nil;
        WLBatchEditPictureViewController *editController = [WLBatchEditPictureViewController instantiate:self.storyboard];
        editController.pictures = weakSelf.pictures;
        editController.delegate = weakSelf;
        editController.wrap = weakSelf.wrap;
        [weakSelf pushViewController:editController animated:NO];
    };
    
    if (queue.operations.count == 0) {
        completionBlock();
    } else {
        sender.loading = YES;
        [queue setFinishQueueBlock:^{
            sender.loading = NO;
            completionBlock();
        }];
    }
}

- (void)cameraViewController:(WLCameraViewController *)controller didSelectAssets:(NSArray *)assets {
    [self handleAssets:assets];
}

- (void)handleAssets:(NSArray*)assets {
    __weak typeof(self)weakSelf = self;
    for (ALAsset* asset in assets) {
        WLEditPicture *picture = [WLEditPicture picture:weakSelf.mode];
        picture.isAsset = YES;
        [self.pictures addObject:picture];
        [self updatePicturesCountLabel];
        runQueuedOperation(@"wl_still_picture_queue",3,^(WLOperation *operation) {
            [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                [picture setImage:croppedImage completion:^(id object) {
                    [operation finish];
                }];
            }];
        });
    }
}

- (void)updatePicturesCountLabel {
    [self.cameraViewController.takePhotoButton setTitle:[NSString stringWithFormat:@"%lu", (unsigned long)self.pictures.count] forState:UIControlStateNormal];
    self.cameraViewController.finishButton.active = self.pictures.count > 0;
}

#pragma mark - WLBatchEditPictureViewControllerDelegate

- (void)batchEditPictureViewController:(WLBatchEditPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    
    for (WLEditPicture *picture in pictures) {
        [picture saveToAssetsIfNeeded];
    }
    
    [self finishWithPictures:pictures];
}

#pragma mark - WLAssetsViewControllerDelegate

- (void)assetsViewController:(id)controller didSelectAssets:(NSArray *)assets {
    [self popToRootViewControllerAnimated:YES];
    [self handleAssets:assets];
}

@end
