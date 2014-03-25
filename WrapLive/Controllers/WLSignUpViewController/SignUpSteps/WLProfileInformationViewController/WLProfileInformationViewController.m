//
//  WLProfileInformationViewController.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 3/25/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLProfileInformationViewController.h"
#import "WLHomeViewController.h"
#import "WLCameraViewController.h"

@interface WLProfileInformationViewController () <UITextFieldDelegate, WLCameraViewControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) IBOutlet UIButton *createImageButton;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;

@property (nonatomic, readonly) UIViewController* signUpViewController;

@end

@implementation WLProfileInformationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
	
}

- (UIViewController *)signUpViewController {
	return self.navigationController.parentViewController;
}

- (IBAction)continue:(id)sender {
	WLHomeViewController * controller = [self.signUpViewController.storyboard instantiateViewControllerWithIdentifier:@"home"];
	[self.signUpViewController.navigationController pushViewController:controller animated:YES];
}

- (IBAction)createImage:(id)sender {
	WLCameraViewController * controller = [self.signUpViewController.storyboard instantiateViewControllerWithIdentifier:@"camera"];
	controller.delegate = self;
	[self.signUpViewController presentViewController:controller animated:YES completion:nil];
}

#pragma mark - WLCameraViewControllerDelegate

- (void)cameraViewControllerDidCancel:(WLCameraViewController *)controller {
	[self.signUpViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraViewController:(WLCameraViewController *)controller didFinishWithImage:(UIImage *)image {
	self.profileImageView.image = image;
	[self.signUpViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

@end
