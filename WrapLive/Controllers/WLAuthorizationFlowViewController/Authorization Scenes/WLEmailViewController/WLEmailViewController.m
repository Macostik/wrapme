//
//  WLEmailViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmailViewController.h"
#import "WLAuthorization.h"

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
    [self.delegate emailViewController:self didFinishWithEmail:self.emailField.text];
}

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight/2.0f;
}

@end
