//
//  WLWrapSettingsViewController.m
//  meWrap
//
//  Created by Yura Granchenko on 11/06/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapSettingsViewController.h"
#import "WLToast.h"
#import "WLButton.h"

@interface WLWrapSettingsViewController () <EntryNotifying>

@property (weak, nonatomic) IBOutlet UITextField *wrapNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *actionButton;
@property (weak, nonatomic) IBOutlet UISwitch *candyNotifyTrigger;
@property (weak, nonatomic) IBOutlet UISwitch *chatNotifyTrigger;
@property (weak, nonatomic) IBOutlet UISwitch *restictedInviteTrigger;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *friendsInvitePrioritizer;
@property (weak, nonatomic) IBOutlet LayoutPrioritizer *chatPrioritizer;

@property (strong, nonatomic) EditSession *editSession;

@property (nonatomic) BOOL userInitiatedDestructiveAction;

@property (strong, nonatomic) RunQueue *runQueue;

@end

@implementation WLWrapSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.runQueue = [[RunQueue alloc] initWithLimit:1];
    
    Wrap *wrap = self.wrap;
    
    NSString *title = (wrap.deletable ? @"delete_wrap" : (wrap.isPublic ? @"following" :  @"leave_wrap")).ls;
    [self.actionButton setTitle:title forState:UIControlStateNormal];
    
    self.wrapNameTextField.text = wrap.name;
    self.editSession = [[EditSession alloc] initWithOriginalValue:wrap.name setter:^(EditSession * session, NSObject * value) {
        wrap.name = (NSString*)value;
    }];
    
    if (wrap.isPublic && !wrap.contributor.current) {
        BOOL isFollowing = wrap.isContributing;
        self.editButton.hidden = isFollowing;
        self.wrapNameTextField.enabled = !isFollowing;
    }
    
    self.friendsInvitePrioritizer.defaultState = wrap.contributor.current && !wrap.isPublic;
    self.chatPrioritizer.defaultState = !wrap.isPublic;

    [self.candyNotifyTrigger setOn:self.wrap.isCandyNotifiable];
    [self.chatNotifyTrigger setOn:self.wrap.isChatNotifiable];
    [self.restictedInviteTrigger setOn:!self.wrap.isRestrictedInvite];
    self.candyNotifyTrigger.userInteractionEnabled = NO;
    self.chatNotifyTrigger.userInteractionEnabled = NO;
    
    __weak __typeof(self)weakSelf = self;
    [[WLAPIRequest preferences:self.wrap] send:^(Wrap *wrap) {
        [weakSelf.candyNotifyTrigger setOn:wrap.isCandyNotifiable];
        [weakSelf.chatNotifyTrigger setOn:wrap.isChatNotifiable];
        weakSelf.candyNotifyTrigger.userInteractionEnabled = YES;
        weakSelf.chatNotifyTrigger.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        weakSelf.candyNotifyTrigger.userInteractionEnabled = YES;
        weakSelf.chatNotifyTrigger.userInteractionEnabled = YES;
    }];
    [[Wrap notifier] addReceiver:self];
}

- (IBAction)handleAction:(WLButton *)sender {
    __weak __typeof(self)weakSelf = self;
    Wrap *wrap = self.wrap;
    BOOL deletable = wrap.deletable;
    [UIAlertController confirmWrapDeleting:wrap success:^(UIAlertAction *action) {
        weakSelf.userInitiatedDestructiveAction = YES;
        sender.loading = YES;
        weakSelf.view.userInteractionEnabled = NO;
        [wrap delete:^(id object) {
            if (wrap.isPublic) {
                [weakSelf.navigationController popViewControllerAnimated:NO];
            } else {
                [weakSelf.navigationController popToRootViewControllerAnimated:NO];
                if (deletable) [WLToast showWithMessage:@"delete_wrap_success".ls];
            }
            sender.loading = NO;
        } failure:^(NSError *error) {
            weakSelf.userInitiatedDestructiveAction = NO;
            [error show];
            sender.loading = NO;
            weakSelf.view.userInteractionEnabled = YES;
        }];
    } failure:nil];
}

- (IBAction)changeSwichValue:(id)sender {
    [self enqueueSelector:@selector(performUploadPreferenceRequest) delay:1.0];
}

- (void)performUploadPreferenceRequest {
    BOOL candyNotify = self.candyNotifyTrigger.on;
    BOOL chatNotify = self.chatNotifyTrigger.on;
    __weak typeof(self)weakSelf = self;
    Wrap *wrap = self.wrap;
    [self.runQueue run:^(Block finish) {
        BOOL _candyNotify = wrap.isCandyNotifiable;
        BOOL _chatNotify = wrap.isChatNotifiable;
        wrap.isCandyNotifiable = candyNotify;
        wrap.isChatNotifiable = chatNotify;
        [[WLAPIRequest changePreferences:wrap] send:^(id object) {
            finish();
        } failure:^(NSError *error) {
            finish();
            weakSelf.candyNotifyTrigger.on = wrap.isCandyNotifiable = _candyNotify;
            weakSelf.chatNotifyTrigger.on = wrap.isChatNotifiable = _chatNotify;
        }];
    }];
}

- (IBAction)editButtonClick:(UIButton *)sender {
    if  (sender.selected) {
        [self.editSession reset];
        [self.wrapNameTextField resignFirstResponder];
        self.wrapNameTextField.text = (NSString*)self.editSession.originalValue;
    } else {
        [self.wrapNameTextField becomeFirstResponder];
    }
}

// MARK: - UITextFieldHandler

- (IBAction)textFieldEditChange:(UITextField *)sender {
    if (sender.text.length > [Constants wrapNameLimit]) {
        sender.text = [sender.text substringToIndex:[Constants wrapNameLimit]];
    }
    self.editSession.changedValue = [sender.text trim];
    self.editButton.selected = self.editSession.hasChanges;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    __weak __typeof(self)weakSelf = self;
    Wrap *wrap = self.wrap;
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
        [WLToast showWithMessage:@"wrap_name_cannot_be_blank".ls];
        self.wrapNameTextField.text = (NSString*)self.editSession.originalValue;
    }
    self.editButton.selected = NO;
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)handleFriendsInvite:(UISwitch *)sender {
    Wrap *wrap = self.wrap;
    sender.userInteractionEnabled = NO;
    wrap.isRestrictedInvite = !sender.isOn;
    [wrap update:^(Wrap *wrap) {
        [sender setOn:!wrap.isRestrictedInvite];
        sender.userInteractionEnabled = YES;
    } failure:^(NSError *error) {
        sender.userInteractionEnabled = YES;
    }];
}

// MARK: - EntryNotifying

- (void)notifier:(EntryNotifier *)notifier willDeleteEntry:(Entry *)entry {
    Wrap *wrap = (Wrap*)entry;
    if (self.viewAppeared && !self.userInitiatedDestructiveAction) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        if (!wrap.deletable) {
            [WLToast showMessageForUnavailableWrap:wrap];
        }
    }
}

- (BOOL)notifier:(EntryNotifier *)notifier shouldNotifyOnEntry:(Entry *)entry {
    return self.wrap == entry;
}

@end
