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
    
    for (UIView* subview in self.view.subviews) {
        NSUInteger index = [self.view.subviews indexOfObject:subview];
        subview.transform = CGAffineTransformMakeTranslation(-self.view.bounds.size.width, 0);
        [UIView animateWithDuration:0.5 delay:index/20.0f usingSpringWithDamping:0.7 initialSpringVelocity:0.7 options:UIViewAnimationOptionCurveEaseIn animations:^{
            subview.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }
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
                    [weakSelf showViewControllerForStatus:WLEmailStepStatusVerification animated:YES];
                } else {
                    [weakSelf showViewControllerForStatus:WLEmailStepStatusLinkDevice animated:YES];
                }
            } else {
                [weakSelf showViewControllerForStatus:WLEmailStepStatusUnconfirmedEmail animated:YES];
            }
        } else {
            [weakSelf showViewControllerForStatus:WLEmailStepStatusVerification animated:YES];
        }
    } failure:^(NSError *error) {
        
    }];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

@end
