//
//  WLWrapSettingsViewController.m
//  meWrap
//
//  Created by Yura Granchenko on 11/06/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapSettingsViewController.h"
#import "WLToast.h"
#import "WLEditSession.h"
#import "WLAlertView.h"
#import "WLButton.h"
#import "WLLayoutPrioritizer.h"

@interface WLWrapSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *wrapNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UISwitch *candyNotifyTrigger;
@property (weak, nonatomic) IBOutlet UISwitch *chatNotifyTrigger;
@property (weak, nonatomic) IBOutlet UISwitch *restictedInviteTrigger;
@property (weak, nonatomic) IBOutlet WLLayoutPrioritizer *friendsInvitePrioritizer;

@property (strong, nonatomic) WLEditSession *editSession;

@end

@implementation WLWrapSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WLWrap *wrap = self.wrap;
    
    NSString *title = WLLS(wrap.deletable ? @"delete_wrap" : (wrap.isPublic ? @"following" :  @"leave_wrap"));
    [self.actionButton setTitle:title forState:UIControlStateNormal];
    
    self.wrapNameTextField.text = wrap.name;
    self.editSession = [[WLEditSession alloc] initWithEntry:wrap stringProperties:@"name", nil];
    
    if (wrap.isPublic && !wrap.contributedByCurrentUser) {
        BOOL isFollowing = wrap.isContributing;
        self.editButton.hidden = isFollowing;
        self.wrapNameTextField.enabled = !isFollowing;
    }
    
    self.friendsInvitePrioritizer.defaultState = wrap.contributedByCurrentUser && !wrap.isPublic;

    [self.candyNotifyTrigger setOn:self.wrap.isCandyNotifiable];
    [self.chatNotifyTrigger setOn:self.wrap.isChatNotifiable];
    [self.restictedInviteTrigger setOn:!self.wrap.isRestrictedInvite];
    self.candyNotifyTrigger.userInteractionEnabled = NO;
    self.chatNotifyTrigger.userInteractionEnabled = NO;
    
    __weak __typeof(self)weakSelf = self;
    [[WLAPIRequest preferences:self.wrap] send:^(WLWrap *wrap) {
        [weakSelf.candyNotifyTrigger setOn:wrap.isCandyNotifiable];
        [weakSelf.chatNotifyTrigger setOn:wrap.isChatNotifiable];
        weakSelf.candyNotifyTrigger.userInteractionEnabled = YES;
        weakSelf.chatNotifyTrigger.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        weakSelf.candyNotifyTrigger.userInteractionEnabled = YES;
        weakSelf.chatNotifyTrigger.userInteractionEnabled = YES;
    }];
    [self addNotifyReceivers];
}

- (void)addNotifyReceivers {
    __weak typeof(self)weakSelf = self;
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        receiver.willDeleteBlock = ^(WLWrap *wrap) {
            if (weakSelf.viewAppeared) {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                if (!wrap.deletable) {
                    [WLToast showMessageForUnavailableWrap:wrap];
                }
            }
        };
    }];
}

- (IBAction)handleAction:(WLButton *)sender {
    __weak __typeof(self)weakSelf = self;
    WLWrap *wrap = self.wrap;
    BOOL deletable = wrap.deletable;
    [UIAlertController confirmWrapDeleting:wrap success:^{
        sender.loading = YES;
        weakSelf.view.userInteractionEnabled = NO;
        [wrap remove:^(id object) {
            if (wrap.isPublic) {
                [weakSelf.navigationController popViewControllerAnimated:NO];
            } else {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                if (deletable) [WLToast showWithMessage:WLLS(@"delete_wrap_success")];
            }
            sender.loading = NO;
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
            weakSelf.view.userInteractionEnabled = YES;
        }];
    } failure:nil];
}

- (IBAction)changeSwichValue:(id)sender {
    [self enqueueSelectorPerforming:@selector(performUploadPreferenceRequest) afterDelay:1.0];
}

- (void)performUploadPreferenceRequest {
    BOOL candyNotify = self.candyNotifyTrigger.on;
    BOOL chatNotify = self.chatNotifyTrigger.on;
    __weak typeof(self)weakSelf = self;
    WLWrap *wrap = self.wrap;
    runUnaryQueuedOperation(@"wl_changing_notification_preferences_queue", ^(WLOperation *operation) {
        BOOL _candyNotify = wrap.isCandyNotifiable;
        BOOL _chatNotify = wrap.isChatNotifiable;
        wrap.isCandyNotifiable = candyNotify;
        wrap.isChatNotifiable = chatNotify;
        [[WLAPIRequest changePreferences:wrap] send:^(id object) {
            [operation finish];
        } failure:^(NSError *error) {
            [operation finish];
            weakSelf.candyNotifyTrigger.on = wrap.isCandyNotifiable = _candyNotify;
            weakSelf.chatNotifyTrigger.on = wrap.isChatNotifiable = _chatNotify;
        }];
    });
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
    __weak __typeof(self)weakSelf = self;
    WLWrap *wrap = self.wrap;
    NSString *name = [textField.text trim];
    if (name.nonempty) {
        if (self.editSession.hasChanges) {
            wrap.name = name;
            [wrap update:^(id object) {
                weakSelf.editButton.selected = NO;
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

- (IBAction)handleFriendsInvite:(UISwitch *)sender {
    WLWrap *wrap = self.wrap;
    sender.userInteractionEnabled = NO;
    wrap.isRestrictedInvite = !sender.isOn;
    [wrap update:^(WLWrap *wrap) {
        [sender setOn:!wrap.isRestrictedInvite];
        sender.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
    }];
}

@end
