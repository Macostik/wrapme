//
//  WLCreateWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSArray+Additions.h"
#import "NSString+Additions.h"
#import "UIButton+Additions.h"
#import "UIColor+CustomColors.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLAPIManager.h"
#import "WLAddContributorsViewController.h"
#import "WLAddressBook.h"
#import "WLActionViewController.h"
#import "WLButton.h"
#import "WLCameraViewController.h"
#import "WLContributorCell.h"
#import "WLCreateWrapViewController.h"
#import "WLEntryNotifier.h"
#import "WLImageCache.h"
#import "WLImageFetcher.h"
#import "WLInviteeCell.h"
#import "WLNavigation.h"
#import "WLPerson.h"
#import "WLToast.h"
#import "WLStillPictureViewController.h"
#import "WLUser.h"
#import "WLWrap.h"
#import "WLWrapViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface WLCreateWrapViewController () <UITextFieldDelegate, WLStillPictureViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic)WLWrap *wrap;

@end

@implementation WLCreateWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = self.contentView.frame;
    self.nameField.layer.borderColor = [UIColor WL_grayColor].CGColor;
    self.createButton.layer.borderColor = self.backButton.layer.borderColor = [UIColor WL_orangeColor].CGColor;
    [self.contentView bottomPushWithDuration:1.0 delegate:nil];

    [self.nameField becomeFirstResponder];
}

- (void)createWrapWithName:(NSString *)name {
    __weak typeof(self)weakSelf = self;
    self.wrap = [WLWrap wrap];
    self.wrap.name = name;
    [self.wrap notifyOnAddition];
    [[WLUploading uploading:self.wrap] upload:^(id object) {
    } failure:^(NSError *error) {
        if ([error isNetworkError]) {
            [error show];
            [weakSelf.wrap remove];
        }
    }];
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    id parentViewController = [self parentViewController];
    if (parentViewController != nil) {
        [parentViewController dismiss];
    }
}

- (IBAction)done:(WLButton*)sender {
    NSString* name = self.nameField.text;
    if (name.nonempty) {
        [self.view endEditing:YES];
        sender.loading = YES;
        self.view.userInteractionEnabled = NO;
        [self createWrapWithName:name];
        WLStillPictureViewController* cameraNavigation = [WLStillPictureViewController instantiate:
                                                          [UIStoryboard storyboardNamed:WLCameraStoryboard]];
        cameraNavigation.delegate = self;
        cameraNavigation.mode = WLCameraModeCandy;
        WLActionViewController *parentViewController = (WLActionViewController *)[self parentViewController];
        if (parentViewController != nil) {
            [parentViewController willAddChildViewController:parentViewController];
            self.view.userInteractionEnabled = YES;
            sender.loading = NO;
        }
    }
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	if (sender.text.length > WLWrapNameLimit) {
		sender.text = [sender.text substringToIndex:WLWrapNameLimit];
	}
    self.createButton.enabled = sender.text.nonempty;
}

#pragma mark - WLStillPictureViewControllerDelegate

- (void)stillPictureViewController:(WLStillPictureViewController *)controller didFinishWithPictures:(NSArray *)pictures {
    if (pictures.nonempty) {
        [self.wrap uploadPictures:pictures];
    }
    [self cancel:nil];
}

- (void)stillPictureViewControllerDidCancel:(WLStillPictureViewController *)controller {
    [self cancel:nil];
}

@end
