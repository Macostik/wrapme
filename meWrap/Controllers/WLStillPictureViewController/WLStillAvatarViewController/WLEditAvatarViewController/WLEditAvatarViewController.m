//
//  WLUploadPhotoViewController.m
//  meWrap
//
//  Created by Ravenpod on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditAvatarViewController.h"
#import "WLNavigationHelper.h"
#import "WLAlertView.h"
#import "WLToast.h"
#import "AdobeUXImageEditorViewController+SharedEditing.h"

@interface WLEditAvatarViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;

@end

@implementation WLEditAvatarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.imageView.image = self.image;
    
    [UIView performWithoutAnimation:^{
        [UIViewController attemptRotationToDeviceOrientation];
    }];
}

- (void)requestAuthorizationForPresentingEntry:(WLEntry *)entry completion:(WLBooleanBlock)completion {
    if (!completion) return;
    [WLAlertView showWithTitle:WLLS(@"unsaved_photo")
                       message:WLLS(@"leave_screen_on_editing")
                       buttons:@[WLLS(@"cancel"),WLLS(@"continue")]
                    completion:^(NSUInteger index) {
                        completion(index == 1);
                    }];
}

// MARK: - actions

- (IBAction)edit:(id)sender {
    __weak typeof(self)weakSelf = self;
    AFPhotoEditorController* aviaryController = [AdobeUXImageEditorViewController editControllerWithImage:self.image completion:^(UIImage *image, AdobeUXImageEditorViewController *controller) {
        weakSelf.image = weakSelf.imageView.image = image;
        [weakSelf.navigationController popViewControllerAnimated:NO];
    } cancel:^(AdobeUXImageEditorViewController *controller) {
        [weakSelf.navigationController popViewControllerAnimated:NO];
    }];
    [self.navigationController pushViewController:aviaryController animated:NO];
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)done:(id)sender {
    [self.view endEditing:YES];
    if (self.completionBlock) self.completionBlock(self.image, nil);
}

// MARK: - rotation and keyboard

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
