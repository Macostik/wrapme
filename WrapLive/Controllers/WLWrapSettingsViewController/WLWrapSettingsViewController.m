//
//  WLWrapSettingsViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/06/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapSettingsViewController.h"
#import "WLAPIManager.h"
#import "WLIconButton.h"
#import "WLToast.h"
#import "WLEditSession.h"
#import "WLPreferenceRequest.h"
#import "WLUploadPreferenceRequest.h"

static NSInteger WLIndent = 12.0;

@interface WLWrapSettingsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *wrapNameTextField;
@property (weak, nonatomic) IBOutlet WLIconButton *editButton;
@property (weak, nonatomic) IBOutlet WLButton *actionButton;
@property (weak, nonatomic) IBOutlet UISwitch *candyNotifyTrigger;
@property (weak, nonatomic) IBOutlet UISwitch *chatNotifyTrigger;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *widthTextFieldConstraint;

@property (strong, nonatomic) WLEditSession *editSession;

@end

@implementation WLWrapSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.actionButton setTitle:self.wrap.deletable ? WLLS(@"delete_wrap") : WLLS(@"leave_wrap")  forState:UIControlStateNormal];
    self.wrapNameTextField.text = self.wrapNameLabel.text = self.wrap.name;
    self.editButton.hidden = !self.wrap.deletable;
    self.wrapNameTextField.enabled = self.wrap.deletable;
    self.editSession = [[WLEditSession alloc] initWithEntry:self.wrap stringProperties:@"name", nil];
    self.widthTextFieldConstraint.constant += !self.wrap.deletable ? : self.editButton.width + WLIndent;
    
    [self.candyNotifyTrigger setOn:self.wrap.isCandyNotifiable];
    [self.chatNotifyTrigger setOn:self.wrap.isChatNotifiable];
    
    __weak __typeof(self)weakSelf = self;
    [[WLPreferenceRequest request:self.wrap] send:^(WLWrap *wrap) {
        [weakSelf.candyNotifyTrigger setOn:wrap.isCandyNotifiable];
        [weakSelf.chatNotifyTrigger setOn:wrap.isChatNotifiable];
    } failure:^(NSError *error) {
    }];
}

- (IBAction)handleAction:(WLButton *)sender {
    __weak __typeof(self)weakSelf = self;
    sender.loading = YES;
    if (self.wrap.deletable) {
        [self.wrap remove:^(id object) {
            if (object != nil) {
                [WLToast showWithMessage:WLLS(@"delete_wrap_success")];
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            }
            sender.loading = NO;
        } failure:^(NSError *error) {
            if ([error isError:WLErrorActionCancelled]) {
                [weakSelf.navigationController popViewControllerAnimated:NO];
                sender.loading = NO;
            } else {
                [error show];
                sender.loading = NO;
            }
        }];
    } else {
        [self.wrap leave:^(id object) {
            if (object != nil) {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            }
            sender.loading = NO;
        } failure:^(NSError *error) {
            if ([error isError:WLErrorActionCancelled]) {
                [weakSelf.navigationController popViewControllerAnimated:NO];
                sender.loading = NO;
            } else {
                [error show];
                sender.loading = NO;
            }
        }];
    }
}

- (IBAction)changeSwichValue:(id)sender {
    WLUploadPreferenceRequest *request = [WLUploadPreferenceRequest request:self.wrap];
    request.candyNotify = self.candyNotifyTrigger.isOn;
    request.chatNotify = self.chatNotifyTrigger.isOn;
    [request send:^(id object) {
    } failure:^(NSError *error) {
    }];
}

- (IBAction)editButtonClick:(UIButton *)sender {
    if  (sender.selected) {
        [self.editSession reset];
        [self.wrapNameTextField resignFirstResponder];
        self.wrapNameTextField.text = [self.editSession originalValueForProperty:@"name"];
    } else {
        [self.wrapNameTextField becomeFirstResponder];
    }
}

// MARK: - UITextFieldHandler

- (IBAction)textFieldEditChange:(UITextField *)sender {
    if (sender.text.length > WLWrapNameLimit) {
        sender.text = [sender.text substringToIndex:WLWrapNameLimit];
    }
    [self.editSession changeValue:[sender.text trim] forProperty:@"name"];
    self.editButton.selected = self.editSession.hasChanges;
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *name = [textField.text trim];
    if (name.nonempty) {
        if (self.editSession.hasChanges) {
            self.wrap.name = name;
            self.wrapNameLabel.text = name;
            [self.wrap update:^(id object) {
            } failure:^(NSError *error) {
            }];
        }
    } else {
        [WLToast showWithMessage:WLLS(@"wrap_name_cannot_be_blank")];
        self.wrapNameTextField.text = [self.editSession originalValueForProperty:@"name"];
    }
    self.editButton.selected = NO;
    [textField resignFirstResponder];
    return YES;
}

@end
