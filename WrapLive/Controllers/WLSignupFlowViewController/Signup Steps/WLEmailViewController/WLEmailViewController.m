//
//  WLEmailViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailViewController.h"
#import "WLAuthorization.h"
#import "WLAuthorizationRequest.h"
#import "WLTelephony.h"
#import "WLButton.h"
#import "WLTestUserPicker.h"
#import "UIAlertView+Blocks.h"
#import "WLNavigation.h"
#import "NSObject+NibAdditions.h"
#import "WLConfirmView.h"

@interface WLEmailViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UIButton *testAccountButton;

@end

@implementation WLEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.emailField.text = [WLAuthorization currentAuthorization].email;
    
    for (UIView* subview in self.view.subviews) {
        NSUInteger index = [self.view.subviews indexOfObject:subview];
        subview.transform = CGAffineTransformMakeTranslation(-self.view.bounds.size.width, 0);
        [UIView animateWithDuration:0.5 delay:index/20.0f usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseIn animations:^{
            subview.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }
    
    self.testAccountButton.hidden = ![WLAPIManager instance].environment.useTestUsers;
}

- (IBAction)next:(WLButton*)sender {
    sender.loading = YES;
    [self.view endEditing:YES];
    WLWhoIsRequest* request = [WLWhoIsRequest request];
    request.email = self.emailField.text;
    __weak typeof(self)weakSelf = self;
    [request send:^(WLWhoIs* whoIs) {
        sender.loading = NO;
        if (whoIs.found && whoIs.requiresApproving) {
            if (whoIs.confirmed) {
                [weakSelf setStatus:WLEmailStepStatusLinkDevice animated:YES];
            } else {
                [weakSelf setStatus:WLEmailStepStatusUnconfirmedEmail animated:YES];
            }
        } else {
            [weakSelf setStatus:WLEmailStepStatusVerification animated:YES];
        }
    } failure:^(NSError *error) {
        sender.loading = NO;
    }];
}

- (IBAction)useTestAccount:(id)sender {
    __weak typeof(self)weakSelf = self;
    [WLTestUserPicker showInView:self.view.window selection:^(WLAuthorization *authorization) {
        [WLConfirmView showInView:weakSelf.view authorization:authorization success:^(WLAuthorization *authorization) {
            if (authorization.password.nonempty) {
                [authorization signIn:^(WLUser *user) {
                    [[UIStoryboard storyboardNamed:WLMainStoryboard] present:NO];
                } failure:^(NSError *error) {
                    [error show];
                }];
            }
        } cancel:nil];
    }];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

@end
