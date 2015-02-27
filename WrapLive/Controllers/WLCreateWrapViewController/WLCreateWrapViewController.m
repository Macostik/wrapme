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
#import "WLButton.h"
#import "WLCameraViewController.h"
#import "WLContributorCell.h"
#import "WLCreateWrapViewController.h"
#import "WLEntryNotifier.h"
#import "WLImageCache.h"
#import "WLImageFetcher.h"
#import "WLInviteeCell.h"
#import "WLNavigation.h"
#import "WLAddressBookPhoneNumber.h"
#import "WLToast.h"
#import "WLUser.h"
#import "WLWrap.h"
#import "WLWrapViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface WLCreateWrapViewController () 

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (strong, nonatomic)WLWrap *wrap;

@end

@implementation WLCreateWrapViewController

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    if (self.cancelHandler)
        self.cancelHandler();
}

- (IBAction)done:(WLButton*)sender {
    NSString* name = [self.nameField.text trim];
    if (!name.nonempty) {
        [WLToast showWithMessage:WLLS(@"Wrap name cannot be blank.")];
        return;
    }
    [self.nameField resignFirstResponder];
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    self.wrap = [WLWrap wrap];
    self.wrap.name = name;
    [self.wrap notifyOnAddition];
    [[WLUploading uploading:self.wrap] upload:^(id object) {
        sender.loading = NO;
        if (weakSelf.createHandler) weakSelf.createHandler(weakSelf.wrap);
    } failure:^(NSError *error) {
        sender.loading = NO;
        if ([error isNetworkError]) {
            if (weakSelf.createHandler) weakSelf.createHandler(weakSelf.wrap);
        } else {
            [error show];
            [weakSelf.wrap remove];
        }
    }];
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	if (sender.text.length > WLWrapNameLimit) {
		sender.text = [sender.text substringToIndex:WLWrapNameLimit];
	}
    self.createButton.enabled = sender.text.nonempty;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
