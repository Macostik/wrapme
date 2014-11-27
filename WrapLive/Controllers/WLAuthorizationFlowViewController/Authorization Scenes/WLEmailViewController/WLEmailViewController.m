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

@interface WLEmailViewController ()

@property (weak, nonatomic) IBOutlet UITextField *emailField;

@end

@implementation WLEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.emailField.text = [WLAuthorization currentAuthorization].email;
}

- (IBAction)next:(id)sender {
    [self.view endEditing:YES];
    WLWhoIsRequest* request = [WLWhoIsRequest request];
    request.email = self.emailField.text;
    __weak typeof(self)weakSelf = self;
    [request send:^(WLWhoIs* whoIs) {
        if (whoIs.found && !whoIs.requiresVerification) {
            if (whoIs.confirmed) {
                if ([WLTelephony hasPhoneNumber]) {
                    [weakSelf showViewControllerForStatus:WLEmailViewControllerCompletionStatusVerification animated:YES];
                } else {
                    [weakSelf showViewControllerForStatus:WLEmailViewControllerCompletionStatusLinkDevice animated:YES];
                }
            } else {
                [weakSelf showViewControllerForStatus:WLEmailViewControllerCompletionStatusUnconfirmedEmail animated:YES];
            }
        } else {
            [weakSelf showViewControllerForStatus:WLEmailViewControllerCompletionStatusVerification animated:YES];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

@end
