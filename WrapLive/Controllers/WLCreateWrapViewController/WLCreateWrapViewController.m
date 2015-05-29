//
//  WLCreateWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSArray+Additions.h"
#import "UIButton+Additions.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLAddressBook.h"
#import "WLButton.h"
#import "WLContributorCell.h"
#import "WLCreateWrapViewController.h"
#import "WLNavigationHelper.h"
#import "WLToast.h"

@interface WLCreateWrapViewController () 

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (strong, nonatomic)WLWrap *wrap;

@end

@implementation WLCreateWrapViewController

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
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
        [WLToast showWithMessage:WLLS(@"wrap_name_cannot_be_blank")];
        return;
    }
    [self.nameField resignFirstResponder];
    sender.loading = YES;
    __weak typeof(self)weakSelf = self;
    self.wrap = [WLWrap wrap];
    self.wrap.name = name;
    [self.wrap notifyOnAddition];
    [WLUploadingQueue upload:[WLUploading uploading:self.wrap] success:^(id object) {
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

- (BOOL)prefersStatusBarHidden {
    return YES;
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
