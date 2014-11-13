//
//  WLStillPictureViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 30.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "ALAssetsLibrary+Additions.h"
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "AsynchronousOperation.h"
#import "WLActionViewController.h"
#import "NSMutableDictionary+ImageMetadata.h"
#import "UIImage+Resize.h"
#import "UIView+AnimationHelper.h"
#import "UIView+Shorthand.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLActionViewController.h"
#import "WLAssetsGroupViewController.h"
#import "WLEntryManager.h"
#import "WLImageFetcher.h"
#import "WLNavigation.h"
#import "WLStillPictureViewController.h"
#import "WLWrap.h"
#import <AviarySDK/AviarySDK.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "WLPickerViewController.h"
#import "WLCreateWrapViewController.h"

static CGFloat WLBottomViewHeight = 92.0f;

@interface WLStillPictureViewController () <WLCameraViewControllerDelegate, AFPhotoEditorControllerDelegate,
                                            UINavigationControllerDelegate, WLPickerViewDelegate, WLCreateWrapDelegate>

@property (weak, nonatomic) UINavigationController* cameraNavigationController;
@property (weak, nonatomic) WLPickerViewController *pickerViewController;
@property (strong, nonatomic) AFPhotoEditorController* aviaryController;

@property (weak, nonatomic) IBOutlet UIView* wrapView;
@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WLImageView *wrapCoverView;

@property (strong, nonatomic) WLImageBlock editBlock;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomAlignment;
@property (strong, nonatomic) IBOutlet UIButton *lockButton;

@end

@implementation WLStillPictureViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    self.editable = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cameraViewController = self.mode == WLCameraModeCandy ? [WLCameraViewController instantiateWithIdentifier:@"WLFullSizeCameraViewController" storyboard:[UIStoryboard storyboardNamed:WLCameraStoryboard]] : [WLCameraViewController instantiate:[UIStoryboard storyboardNamed:WLCameraStoryboard]];
    self.cameraViewController.delegate = self;
    self.cameraViewController.mode = self.mode;
    self.cameraViewController.defaultPosition = self.defaultPosition;
    self.cameraNavigationController = [self.childViewControllers lastObject];
    self.cameraNavigationController.delegate = self;
	[self.cameraNavigationController setViewControllers:@[self.cameraViewController]];
    [self setupWrapVeiw:self.wrap];
}

- (void)setTranslucent:(BOOL)translucent animated:(BOOL)animated {
    UIColor* color = [self.wrapView.backgroundColor colorWithAlphaComponent:translucent ? 0.5f : 1.0f];
    self.wrapView.backgroundColor = color;
    self.wrapView.transform = translucent ? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(.0, WLBottomViewHeight);
    [self.wrapView fade];
}

- (void)setupWrapVeiw:(WLWrap *)wrap {
     _wrap = wrap;
    if (self.wrap) {
        self.wrapView.hidden = NO;
        self.wrapNameLabel.text = self.wrap.name;
        self.wrapCoverView.url = self.wrap.picture.small;
        self.wrapCoverView.circled = YES;
    } else {
        self.wrapView.hidden = YES;
    }
}

- (void)setMode:(WLCameraMode)mode {
    _mode = mode;
}

- (void)setDefaultPosition:(AVCaptureDevicePosition)defaultPosition {
    _defaultPosition = defaultPosition;
}

- (CGFloat)imageWidthForCurrentMode {
    WLCameraMode mode = self.mode;
    if (mode == WLCameraModeCandy) {
        return 720;
    } else {
        return 480;
    }
}

- (void)cropImage:(UIImage*)image useCameraAspectRatio:(BOOL)useCameraAspectRatio completion:(void (^)(UIImage *croppedImage))completion {
	CGSize viewSize = self.cameraViewController.viewSize;
	run_getting_object(^id{
        UIImage *result = image;
        CGFloat resultWidth = [self imageWidthForCurrentMode];
        if (useCameraAspectRatio) {
            CGSize newSize = CGSizeThatFitsSize(result.size, viewSize);
            CGFloat scale = newSize.width / resultWidth;
            newSize = CGSizeMake(resultWidth, newSize.height / scale);
            result = [result resizedImageWithContentModeScaleAspectFill:CGSizeMake(result.size.width / scale, 1)];
            if (result.size.width > result.size.height) {
                result = [result croppedImage:CGRectThatFitsSize(result.size, CGSizeMake(newSize.height, newSize.width))];
            } else {
                result = [result croppedImage:CGRectThatFitsSize(result.size, newSize)];
            }
        } else {
            result = [result resizedImageWithContentModeScaleAspectFill:CGSizeMake(resultWidth, 1)];
        }
        return result;
	}, completion);
}

- (void)cropAsset:(ALAsset*)asset completion:(void (^)(UIImage *croppedImage))completion {
    ALAssetRepresentation* r = asset.defaultRepresentation;
    UIImage* image = [UIImage imageWithCGImage:r.fullResolutionImage scale:r.scale orientation:(UIImageOrientation)r.orientation];
    [self cropImage:image useCameraAspectRatio:(self.mode != WLCameraModeCandy) completion:completion];
}

- (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[AFPhotoEditorCustomization setLeftNavigationBarButtonTitle:@"Cancel"];
		[AFPhotoEditorCustomization setRightNavigationBarButtonTitle:@"Save"];
	});
	AFPhotoEditorController* aviaryController = [[AFPhotoEditorController alloc] initWithImage:image];
	aviaryController.delegate = self;
	aviaryController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
	return aviaryController;
}

- (void)handleImage:(UIImage*)image save:(BOOL)save metadata:(NSMutableDictionary *)metadata {
    WLCameraMode mode = self.mode;

    __weak typeof(self)weakSelf = self;
    
    WLImageBlock finishBlock = ^ (UIImage *resultImage) {
        
        if (save) [weakSelf saveImage:image metadata:metadata];
        
        if (mode == WLCameraModeCandy) {
            if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
                weakSelf.view.userInteractionEnabled = NO;
                [WLPicture picture:resultImage completion:^(id object) {
                    [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithPictures:@[object]];
                    weakSelf.view.userInteractionEnabled = YES;
                }];
            }
        } else if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithImage:)]) {
            [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithImage:resultImage];
        }
    };
    
    if (self.editable) {
        [self editImage:image completion:finishBlock];
    } else {
        finishBlock(image);
    }
}

- (void)editImage:(UIImage*)image completion:(WLImageBlock)completion {
    self.aviaryController = [self editControllerWithImage:image];
    [self.cameraNavigationController pushViewController:self.aviaryController animated:YES];
    self.editBlock = completion;
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image metadata:(NSMutableDictionary *)metadata {
	self.view.userInteractionEnabled = NO;
	__weak typeof(self)weakSelf = self;
	[self cropImage:image useCameraAspectRatio:YES completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage save:YES metadata:metadata];
		weakSelf.view.userInteractionEnabled = YES;
	}];
}

- (void)saveImage:(UIImage*)image metadata:(NSMutableDictionary *)metadata {
	[metadata setImageOrientation:image.imageOrientation];
	run_in_default_queue(^{
		ALAssetsLibrary* library = [[ALAssetsLibrary alloc] init];
		[library saveImage:image
				   toAlbum:@"wrapLive"
				  metadata:metadata
				completion:^(NSURL *assetURL, NSError *error) { }
				   failure:^(NSError *error) { }];
	});
}

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self.delegate stillPictureViewControllerDidCancel:self];
}

- (void)cameraViewControllerDidSelectGallery:(WLCameraViewController *)controller {
    
	WLAssetsGroupViewController* gallery = [[WLAssetsGroupViewController alloc] init];
    gallery.mode = self.mode;
	__weak typeof(self)weakSelf = self;
	[gallery setSelectionBlock:^(NSArray *assets) {
        if ([assets count] == 1) {
            [weakSelf handleAsset:[assets firstObject]];
        } else {
            [weakSelf handleAssets:assets];
        }
	}];
    [self setTranslucent:NO animated:YES];
    [weakSelf.cameraNavigationController pushViewController:gallery animated:YES];
}

- (void)handleAsset:(ALAsset*)asset {
    self.view.userInteractionEnabled = NO;
    __weak typeof(self)weakSelf = self;
    [self cropAsset:asset completion:^(UIImage *croppedImage) {
        [weakSelf handleImage:croppedImage save:NO metadata:nil];
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
        [queue addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
            [weakSelf cropAsset:asset completion:^(UIImage *croppedImage) {
                [WLPicture picture:croppedImage completion:^(id object) {
                    [pictures addObject:object];
                    [operation finish:^{
                        run_in_main_queue(^{
                            weakSelf.view.userInteractionEnabled = YES;
                            if ([weakSelf.delegate respondsToSelector:@selector(stillPictureViewController:didFinishWithPictures:)]) {
                                [weakSelf.delegate stillPictureViewController:weakSelf didFinishWithPictures:pictures];
                            }
                        });
                    }];
                }];
            }];
        }];
    }
}

#pragma mark - AFPhotoEditorControllerDelegate

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {
    if (self.editBlock) {
        self.editBlock(image);
        self.editBlock = nil;
    }
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
    [self.cameraNavigationController popViewControllerAnimated:YES];
    self.aviaryController = nil;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if (viewController != self.cameraViewController) {
           [self.wrapView leftPushWithDuration:.15 delegate:nil];
    }
    self.wrapView.hidden = YES;
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    if (self.wrap) {
        self.wrapView.hidden = viewController == self.aviaryController;
        viewController.hidesBottomBarWhenPushed = YES;
        if (viewController == self.cameraViewController) {
            [self setTranslucent:YES animated:YES];
        }
    }
    
}

#pragma mark - PickerViewController action

- (IBAction)chooseWrap:(UIButton *)sender {
    __weak __typeof(self)weakSelf = self;
    if (self.pickerViewController != nil) {
        return;
    }
    WLPickerViewController *pickerViewController = [WLPickerViewController initWithWrap:self.wrap
                                                                               delegate:self
                                                                         selectionBlock:^(WLWrap *wrap) {
        [weakSelf setupWrapVeiw:wrap];
    }];
    self.pickerViewController = pickerViewController;
    [self appearPickerViewController];
}

- (void)hidePickerViewController {
    [self unlockUI];
    UIView *view = self.pickerViewController.view;
    [UIView animateWithDuration:.33 animations:^{
        view.transform = CGAffineTransformIdentity;
    }completion:^(BOOL finished) {
        [view removeFromSuperview];
        [self.pickerViewController removeFromParentViewController];
        self.pickerViewController = nil;
    }];
}

- (void)appearPickerViewController {
    [self lockUI];
    UIView *view = self.pickerViewController.view;
    [self addChildViewController:self.pickerViewController];
    view.origin = (CGPoint){self.view.x, self.view.height};
    view.width = self.view.width;
    [self.view addSubview:view];
    [self didMoveToParentViewController:self.pickerViewController];
    [UIView animateWithDuration:.33 animations:^{
        view.transform = CGAffineTransformMakeTranslation(.0f, -view.height);
    }];
}

- (void)lockUI {
    [self.view bringSubviewToFront:self.lockButton];
}

- (void)unlockUI {
    [self.view sendSubviewToBack:self.lockButton];
    
}

- (IBAction)unlockButtonClick:(id)sender {
    [self hidePickerViewController];
    [self unlockUI];
}

#pragma mark - WLPickerViewDelegate 

- (void)pickerViewController:(WLPickerViewController *)pickerViewController doneClick:(UIButton *)sender {
    [self hidePickerViewController];
}

- (void)pickerViewController:(WLPickerViewController *)pickerViewController newWrapClick:(UIButton *)sender {
    [self willCreateWrap];
}

- (void)willCreateWrap {
    WLCreateWrapViewController *childViewController = [WLActionViewController addViewControllerByClass:
                                                       [WLCreateWrapViewController class] toParentViewController:self];
    childViewController.delegate = self;
    __weak __typeof(self)weakSelf = self;
    [childViewController setHandlerCancelBlock:^{
        [weakSelf dismissViewControllerAnimated:YES completion:NULL];
    }];
}


#pragma mark - WLCreateWrapDelegate

- (void)wlCreateWrapViewController:(WLCreateWrapViewController *)viewController didCreateWrap:(WLWrap *)wrap {
    [self setupWrapVeiw:wrap];
}

@end
