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
@property (weak, nonatomic) IBOutlet UILabel *deleteLabel;

@end

@implementation WLEditWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.contentView.layer.cornerRadius = 6.0f;
    
    self.editSession = [[WLEditSession alloc] initWithEntry:self.wrap stringProperties:@"name", nil];
    
    self.nameWrapTextField.layer.borderColor = [UIColor WL_grayColor].CGColor;
    self.nameWrapTextField.layer.borderWidth = 0.5;
    self.deleteButton.layer.cornerRadius = 3.0f;
    [self.nameWrapTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    [self.nameWrapTextField addTarget:self action:@selector(textFieldEditChange:) forControlEvents:UIControlEventEditingChanged];
    [self.deleteButton addTarget:self action:@selector(deleteButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    BOOL isMyWrap = [self isMyWrap];
    
    self.deleteLabel.text = [NSString stringWithFormat:@"%@ this wrap", isMyWrap ? WLDelete : WLLeave];
    [self.deleteButton setTitle:isMyWrap ? WLDelete : WLLeave forState:UIControlStateNormal];
    self.nameWrapTextField.enabled = isMyWrap;
    [self setupEditableUserInterface];
}

- (void)setupEditableUserInterface {
    self.nameWrapTextField.text = self.wrap.name;
}

- (BOOL)isMyWrap {
    return [self.wrap.contributor isCurrentUser];
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldEditChange:(UITextField *)sender {
    if (sender.text.length > WLWrapNameLimit) {
        sender.text = [sender.text substringToIndex:WLWrapNameLimit];
    }
    [self.editSession changeValue:sender.text forProperty:@"name"];
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

- (IBAction)deleteButtonClick:(id)sender {
    __weak typeof(self)weakSelf = self;
    WLWrap *wrap = self.wrap;
    if ([self isMyWrap]) {
        [wrap remove:^(id object) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        } failure:^(NSError *error) {
            [error show];
        }];
    } else {
        [wrap leave:^(id object) {
            [weakSelf.navigationController popToRootViewControllerAnimated:YES];
        } failure:^(NSError *error) {
            [error show];
        }];
    }
}

@end
