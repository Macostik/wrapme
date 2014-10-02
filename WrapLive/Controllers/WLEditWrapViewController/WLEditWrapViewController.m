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
#import "WLEntryManager.h"
#import "WLAPIManager.h"
#import "WLToast.h"

static NSString *const WLDelete = @"Delete";
static NSString *const WLLeave = @"Leave";

@interface WLEditWrapViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nameWrapTextField;
@property (weak, nonatomic) IBOutlet WLPressButton *deleteButton;
@property (weak, nonatomic) IBOutlet UILabel *deleteLabel;

@end

@implementation WLEditWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.nameWrapTextField.layer.borderWidth = 0.5;
	self.nameWrapTextField.layer.borderColor = [UIColor WL_grayColor].CGColor;
    self.deleteButton.layer.cornerRadius = 3.0f;
    self.nameWrapTextField.text = self.wrap.name;
    [self.nameWrapTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    self.deleteLabel.text = [NSString stringWithFormat:@"%@ this wrap", [self isMyWrap]? WLDelete : WLLeave];
    [self.deleteButton setTitle:[self isMyWrap]? WLDelete : WLLeave forState:UIControlStateNormal];
    self.nameWrapTextField.enabled = [self isMyWrap];
}

- (BOOL)isMyWrap {
    return [self.wrap.contributor isCurrentUser];
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	if (sender.text.length > WLWrapNameLimit) {
		sender.text = [sender.text substringToIndex:WLWrapNameLimit];
    }
}

- (IBAction)textFieldEditChange:(UITextField *)sender {
    [self willShowCancelAndDoneButtons:[self isMyWrap] && ![self.wrap.name isEqualToString:sender.text]];
}

- (IBAction)doneClick:(id)sender {
    __weak __typeof(self)weakSelf = self;
    if (![self.nameWrapTextField.text isEqualToString:self.wrap.name]) {
        WLWrap *wrap = [WLWrap entry:self.wrap.identifier];
        if (wrap) {
            wrap.name = self.nameWrapTextField.text;
            [wrap update:^(id object) {
                [weakSelf back:nil];
            } failure:^(NSError *error) {
                [error show];
            }];
        }
    }
}
- (IBAction)cancelClick:(id)sender {
    [self willShowCancelAndDoneButtons:[self isMyWrap] && [self.wrap.name isEqualToString:self.nameWrapTextField.text]];
    self.nameWrapTextField.text = self.wrap.name;
    [self.view endEditing:YES];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)deleteButtonClick:(id)sender {
    WLWrap *wrap = [WLWrap entry:self.wrap.identifier];
    if ([self isMyWrap]) {
        [wrap remove:^(id object) {
            if (object != nil) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        } failure:^(NSError *error) {
            [error show];
        }];
    } else {
        [wrap leave:^(id object) {
            if (object != nil) {
                [self.navigationController popViewControllerAnimated:YES];
            }
        } failure:^(NSError *error) {
            [error show];
        }];
    }
}

@end
