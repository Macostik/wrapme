//
//  WLEditWrapViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/9/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditWrapViewController.h"
#import "WLButton.h"
#import "UIColor+CustomColors.h"
#import "WLWrap+Extended.h"
#import "WLUser+Extended.h"
#import "NSObject+NibAdditions.h"
#import "UIView+Shorthand.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLEntryManager.h"
#import "WLAPIManager.h"
#import "WLToast.h"

@interface WLEditWrapViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nameWrapTextField;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation WLEditWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.editSession = [[WLEditSession alloc] initWithEntry:self.entry stringProperties:@"name", nil];
    
    [self.nameWrapTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    
    self.nameWrapTextField.enabled = self.entry.deletable;
}

- (void)setupEditableUserInterface {
    self.nameWrapTextField.text = self.entry.name;
}

- (void)setButtonTitle {
       [self.deleteButton setTitle:self.entry.deletable ? WLLS(WLDelete) : WLLS(WLLeave) forState:UIControlStateNormal];
}

- (void)performSelectorByTitle {
    __weak __typeof(self)weakSelf = self;
    [self.entry leave:^(id object) {
        [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        [weakSelf dismissViewControllerAnimated:YES completion:nil];
        weakSelf.deleteButton.loading = NO;
    } failure:^(NSError *error) {
        [error show];
        weakSelf.deleteButton.loading = NO;
    }];
}

- (void)showToast {
    [WLToast showWithMessage:WLLS(@"Wrap was deleted successfully.")];
}

- (IBAction)removeFromController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldEditChange:(UITextField *)sender {
    if (sender.text.length > WLWrapNameLimit) {
        sender.text = [sender.text substringToIndex:WLWrapNameLimit];
    }
    [self.editSession changeValue:sender.text forProperty:@"name"];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - WLEditViewController override method

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (!self.nameWrapTextField.text.nonempty) {
        if (failure) failure([NSError errorWithDescription:WLLS(@"Wrap name cannot be blank.")]);
    } else {
        if (success) success(nil);
    }
}

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.entry update:success failure:success];
}

#pragma mark - WLBaseViewController override method

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

#pragma mark - WLEditSessionDelegate override

- (void)editSession:(WLEditSession *)session hasChanges:(BOOL)hasChanges {
    [super editSession:session hasChanges:hasChanges];
    self.closeButton.hidden = hasChanges;
}

@end
