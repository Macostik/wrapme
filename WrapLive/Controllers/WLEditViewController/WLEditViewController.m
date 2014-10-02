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
#import "WLKeyboardBroadcaster.h"
#import "UIView+AnimationHelper.h"
#import "UIView+QuatzCoreAnimations.h"

@interface WLEditViewController () <WLStillPictureViewControllerDelegate, UITextFieldDelegate>

@end

@implementation WLEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[WLKeyboardBroadcaster broadcaster] addReceiver:self];
}

- (BOOL)isAtObjectSessionChanged {
    BOOL changed = [self.editSession hasChanges];
    [self willShowCancelAndDoneButtons:changed];
    return changed;
}

- (void)willShowCancelAndDoneButtons:(BOOL)showDone {
    self.cancelButton.width = self.view.width/2 - 1;
    self.doneButton.x = self.view.width/2;
    
    self.doneButton.hidden = self.cancelButton.hidden = !showDone;
    [self.cancelButton setAlpha:showDone ? 1 : 0 animated:YES];
    [self.doneButton setAlpha:showDone ? 1 : 0 animated:YES];
}


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

#pragma mark -WLKeyboardBroadcastReceiver

- (void)broadcaster:(WLKeyboardBroadcaster*)broadcaster willShowKeyboardWithHeight:(NSNumber*)keyboardHeight {
    NSTimeInterval duration = [broadcaster.duration doubleValue];
    UIViewAnimationCurve animationCurve = [broadcaster.animationCurve integerValue];
    [self willShowKeyboardWithHeight:keyboardHeight duration:duration option:animationCurve];
}

- (void)broadcasterWillHideKeyboard:(WLKeyboardBroadcaster*)broadcaster {
    NSTimeInterval duration = [broadcaster.duration doubleValue];
    UIViewAnimationCurve animationCurve = [broadcaster.animationCurve integerValue];
    [self willHideKeyboardWithDuration:duration option:animationCurve];
}

- (void)willShowKeyboardWithHeight:(NSNumber *)keyboardHeight
                          duration:(NSTimeInterval)duration
                            option:(UIViewAnimationCurve)animationCurve {
    [UIView performAnimated:YES animation:^{
        [UIView setAnimationCurve:animationCurve];
        self.cancelButton.transform = self.doneButton.transform = CGAffineTransformMakeTranslation(0, -[keyboardHeight integerValue]);
    }];
}

- (void)willHideKeyboardWithDuration:(NSTimeInterval)duration option:(UIViewAnimationCurve)animationCurve {
    [UIView performAnimated:YES animation:^{
        [UIView setAnimationCurve:7];
        self.cancelButton.transform = self.doneButton.transform = CGAffineTransformIdentity;
    }];
}

@end
