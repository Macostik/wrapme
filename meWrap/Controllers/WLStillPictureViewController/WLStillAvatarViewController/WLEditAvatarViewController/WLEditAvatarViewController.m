//
//  WLUploadPhotoViewController.m
//  meWrap
//
//  Created by Ravenpod on 2/20/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEditAvatarViewController.h"
#import "WLToast.h"
#import "WLImageEditorSession.h"

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

- (void)requestAuthorizationForPresentingEntry:(Entry *)entry completion:(BooleanBlock)completion {
    if (!completion) return;
    [[[UIAlertController alert:@"unsaved_photo".ls message:@"leave_screen_on_editing".ls] action:@"cancel".ls handler:^(UIAlertAction *action) {
        completion(NO);
    }] action:@"continue".ls handler:^(UIAlertAction *action) {
        completion(YES);
    }];
}

// MARK: - actions

- (IBAction)edit:(id)sender {
    __weak typeof(self)weakSelf = self;
    UIViewController* controller = [WLImageEditorSession editControllerWithImage:self.image completion:^(UIImage *image) {
        weakSelf.image = weakSelf.imageView.image = image;
        [weakSelf.navigationController popViewControllerAnimated:NO];
    } cancel:^ {
        [weakSelf.navigationController popViewControllerAnimated:NO];
    }];
    [self.navigationController pushViewController:controller animated:NO];
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)done:(id)sender {
    [self.view endEditing:YES];
    if (self.completionBlock) self.completionBlock(self.image, nil);
}

// MARK: - rotation and keyboard

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
