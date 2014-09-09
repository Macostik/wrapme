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
    self.nameWrapTextField.returnKeyType = UIReturnKeyDone;
    self.deleteLabel.text = [NSString stringWithFormat:@"%@ this wrap", [self isMyWrap]? @"Delete" : @"Leave"];
    self.deleteButton.titleLabel.text = [self isMyWrap]? @"Delete" : @"Leave";
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (![textField.text isEqualToString:self.wrap.name]) {
        WLWrap *wrap = [WLWrap entry:self.wrap.identifier];
        if (wrap) {
            wrap.name = textField.text;
            [wrap update:^(id object) {
            } failure:^(NSError *error) {
                [error show];
            }];
        }
    }
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)back:(id)sender {
    [self dismiss];
}

- (IBAction)deleteButtonClick:(id)sender {
    WLWrap *wrap = [WLWrap entry:self.wrap.identifier];
    if ([wrap.contributor isCurrentUser]) {
        [wrap remove:^(id object) {
            [self back:nil];
        } failure:^(NSError *error) {
            [error show];
        }];
    } else {
        [wrap leave:^(id object) {
            [self back:nil];
        } failure:^(NSError *error) {
            [error show];
        }];
    }

}

@end
