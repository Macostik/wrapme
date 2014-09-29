//
//  WLEditViewController.m
//  WrapLive
//
//  Created by Yuriy Granchenko on 10.07.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditViewController.h"
#import "UIView+Shorthand.h"
#import "UIImage+Resize.h"
#import "WLEntryManager.h"
#import "WLNavigation.h"

@interface WLEditViewController () <WLStillPictureViewControllerDelegate, UITextFieldDelegate>

@end

@implementation WLEditViewController

- (BOOL)isAtObjectSessionChanged {
    BOOL changed = [self.editSession hasChanges];
    [self willShowDoneButton:changed];
    return changed;
}

- (void)willShowDoneButton:(BOOL)showDone {
	if (showDone) {
		self.cancelButton.width = self.view.width/2 - 1;
		self.doneButton.x = self.view.width/2;
        [self validateDoneButton];
	} else {
		self.cancelButton.width = self.view.width;
		self.doneButton.x = self.view.width;
	}
}

- (void)validateDoneButton {}

- (void)updateIfNeeded:(void (^)(void))completion{
	[self lock];
	[self.spinner startAnimating];
}

- (IBAction)goToMainScreen:(id)sender {
	__weak typeof(self)weakSelf = self;
	[self updateIfNeeded:^{
		[weakSelf.navigationController popViewControllerAnimated:YES];
	}];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue isCameraSegue]) {
		WLStillPictureViewController* pictureController = segue.destinationViewController;
		pictureController.delegate = self;
		pictureController.defaultPosition = self.stillPictureCameraPosition;
		pictureController.mode = self.stillPictureMode;
	}
}

- (void)lock {
	for (UIView* subview in self.view.subviews) {
		subview.userInteractionEnabled = NO;
	}
}

- (void)unlock {
	for (UIView* subview in self.view.subviews) {
		subview.userInteractionEnabled = YES;
	}
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithImage:(UIImage *)image {
	self.imageView.image = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill
															  bounds:self.imageView.retinaSize
												interpolationQuality:kCGInterpolationDefault];
	[self saveImage:image];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveImage:(UIImage *)image {}

@end
