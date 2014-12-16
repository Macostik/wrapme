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

static NSString *const WLDelete = @"Delete";
static NSString *const WLLeave = @"Leave";

@interface WLEditWrapViewController ()

@property (weak, nonatomic) IBOutlet UITextField *nameWrapTextField;
@property (weak, nonatomic) IBOutlet WLPressButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation WLEditWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.editSession = [[WLEditSession alloc] initWithEntry:self.wrap stringProperties:@"name", nil];
    
    [self.nameWrapTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];

    BOOL isMyWrap = self.wrap.contributedByCurrentUser;
    [self.deleteButton setTitle:isMyWrap ? WLDelete : WLLeave forState:UIControlStateNormal];
    self.nameWrapTextField.enabled = isMyWrap;
}

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)setupEditableUserInterface {
    self.nameWrapTextField.text = self.wrap.name;
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

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (!self.nameWrapTextField.text.nonempty) {
        if (failure) failure([NSError errorWithDescription:@"Wrap name cannot be blank."]);
    } else {
        if (success) success(nil);
    }
}

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    [self.wrap update:success failure:success];
}

- (IBAction)deleteButtonClick:(WLButton*)sender {
    __weak typeof(self)weakSelf = self;
    sender.loading = YES;
    WLWrap *wrap = self.wrap;
    if (wrap.contributedByCurrentUser) {
        [wrap remove:^(id object) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
            sender.loading = NO;
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
        }];
    } else {
        [wrap leave:^(id object) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
            sender.loading = NO;
        } failure:^(NSError *error) {
            [error show];
            sender.loading = NO;
        }];
    }
}

- (IBAction)removeFromController:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

#pragma mark - WLEditSessionDelegate override

- (void)editSession:(WLEditSession *)session hasChanges:(BOOL)hasChanges {
    [super editSession:session hasChanges:hasChanges];
    self.closeButton.hidden = hasChanges;
}

@end
