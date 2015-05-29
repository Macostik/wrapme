//
//  WLEditWrapViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 9/9/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditWrapViewController.h"
#import "WLButton.h"
#import "NSObject+NibAdditions.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLToast.h"

@interface WLEditWrapViewController () <WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UITextField *nameWrapTextField;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet WLPressButton *deleteButton;

@end

@implementation WLEditWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.editSession = [[WLEditSession alloc] initWithEntry:self.wrap stringProperties:@"name", nil];
    
    [self.nameWrapTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    [self.deleteButton setTitle:self.wrap.deletable ? WLLS(@"delete") : WLLS(@"leave") forState:UIControlStateNormal];
    self.nameWrapTextField.enabled = self.wrap.deletable;
    
    [[WLWrap notifier] addReceiver:self];
}

- (void)setupEditableUserInterface {
    self.nameWrapTextField.text = self.wrap.name;
}

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)performSelectorByTitle {
    
    if (!self.wrap.valid) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    
    __weak __typeof(self)weakSelf = self;
    self.deleteButton.loading = YES;
    if (self.wrap.deletable) {
        [self.wrap remove:^(id object) {
            weakSelf.deleteButton.loading = NO;
            [WLToast showWithMessage:WLLS(@"delete_wrap_success")];
            [weakSelf.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        } failure:^(NSError *error) {
            if ([error isError:WLErrorActionCancelled]) {
                [weakSelf.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                weakSelf.deleteButton.loading = NO;
            } else {
                [error show];
                weakSelf.deleteButton.loading = NO;
            }
        }];
    } else {
        [self.wrap leave:^(id object) {
            [weakSelf.navigationController popToRootViewControllerAnimated:NO];
            [weakSelf.presentingViewController dismissViewControllerAnimated:NO completion:nil];
            weakSelf.deleteButton.loading = NO;
        } failure:^(NSError *error) {
            if ([error isError:WLErrorActionCancelled]) {
                [weakSelf.presentingViewController dismissViewControllerAnimated:NO completion:nil];
                weakSelf.deleteButton.loading = NO;
            } else {
                [error show];
                weakSelf.deleteButton.loading = NO;
            }
        }];
    }
}

- (IBAction)removeFromController:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

// MARK: - UITextFieldDelegate

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

// MARK: - WLEditViewController override method

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    NSString *name = [self.nameWrapTextField.text trim];
    if (!name.nonempty) {
        if (failure) failure([NSError errorWithDescription:WLLS(@"wrap_name_cannot_be_blank")]);
    } else {
        if (success) success(nil);
    }
}

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    self.wrap.name = [self.nameWrapTextField.text trim];
    [self.wrap update:success failure:success];
}

// MARK: - WLBaseViewController override method

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

// MARK: - WLEditSessionDelegate override

- (void)editSession:(WLEditSession *)session hasChanges:(BOOL)hasChanges {
    [super editSession:session hasChanges:hasChanges];
    self.closeButton.hidden = hasChanges;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier entryDeleted:(WLWrap *)wrap {
    [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
}

- (BOOL)notifier:(WLEntryNotifier *)notifier shouldNotifyOnEntry:(WLEntry *)entry {
    return self.wrap == entry;
}

@end
