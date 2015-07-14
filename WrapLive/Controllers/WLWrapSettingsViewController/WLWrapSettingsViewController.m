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
#import "WLAlertView.h"

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
    
//    __weak __typeof(self)weakSelf = self;
//    [[WLPreferenceRequest request:self.wrap] send:^(WLWrap *wrap) {
//        [weakSelf.candyNotifyTrigger setOn:wrap.isCandyNotifiable];
//        [weakSelf.chatNotifyTrigger setOn:wrap.isChatNotifiable];
//    } failure:^(NSError *error) {
//    }];
}

- (IBAction)handleAction:(WLButton *)sender {
    __weak __typeof(self)weakSelf = self;
    WLWrap *wrap = self.wrap;
    BOOL deletable = wrap.deletable;
    [WLAlertView confirmWrapDeleting:wrap success:^{
        sender.loading = YES;
        [wrap remove:^(id object) {
            [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            if (deletable) [WLToast showWithMessage:WLLS(@"delete_wrap_success")];
            sender.loading = NO;
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
        }];
    } failure:nil];
}

- (IBAction)changeSwichValue:(id)sender {
    self.wrap.isCandyNotifiable = self.candyNotifyTrigger.isOn;
    self.wrap.isChatNotifiable = self.chatNotifyTrigger.isOn;
   
//    BOOL candyNotify = self.candyNotifyTrigger.isOn;
//    BOOL chatNotify = self.chatNotifyTrigger.isOn;
//    __weak typeof(self)weakSelf = self;
//    runUnaryQueuedOperation(@"wl_changing_notification_preferences_queue", ^(WLOperation *operation) {
//        WLUploadPreferenceRequest *request = [WLUploadPreferenceRequest request:weakSelf.wrap];
//        request.candyNotify = candyNotify;
//        request.chatNotify = chatNotify;
//        [request send:^(id object) {
//            [operation finish];
//        } failure:^(NSError *error) {
//            [operation finish];
//        }];
//    });
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
