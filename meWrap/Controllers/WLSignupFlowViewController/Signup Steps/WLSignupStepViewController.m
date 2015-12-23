//
//  WLAuthorizationSceneViewController.m
//  meWrap
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSignupStepViewController.h"

@interface WLSignupStepViewController ()

@property (strong, nonatomic) NSMutableDictionary* completionBlocks;

@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

@implementation WLSignupStepViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.phoneLabel) {
        self.phoneLabel.text = [Authorization currentAuthorization].fullPhoneNumber;
    }
    
    if (self.emailLabel) {
        self.emailLabel.text = [Authorization currentAuthorization].email;
    }
}

- (CGFloat)keyboardAdjustmentForConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    UIView *firstResponder = [self.view findFirstResponder];
    if (firstResponder) {
        CGFloat responderCenterY = firstResponder.center.y + 64;
        CGFloat centerYOfVisibleSpace = (self.view.height - keyboardHeight - 64)/2 + 64;
        return MAX(0, (responderCenterY - centerYOfVisibleSpace) * constraint.multiplier);
        
    }
    return [Constants isPhone] ? keyboardHeight / 2 : 0;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.navigationController == nil) {
        self.view = nil;
    }
}

- (NSMutableDictionary *)completionBlocks {
    if (!_completionBlocks) {
        _completionBlocks = [NSMutableDictionary dictionary];
    }
    return _completionBlocks;
}

- (void)setCompletionBlock:(WLSignupStepCompletionBlock)block forStatus:(NSUInteger)status {
    [self.completionBlocks setObject:block forKey:@(status)];
}

- (void)setSuccessStatusBlock:(WLSignupStepCompletionBlock)block {
    [self setCompletionBlock:block forStatus:WLSignupStepStatusSuccess];
}

- (void)setFailureStatusBlock:(WLSignupStepCompletionBlock)block {
    [self setCompletionBlock:block forStatus:WLSignupStepStatusFailure];
}

- (void)setCancelStatusBlock:(WLSignupStepCompletionBlock)block {
    [self setCompletionBlock:block forStatus:WLSignupStepStatusCancel];
}

- (WLSignupStepCompletionBlock)completionBlockForStatus:(NSUInteger)status {
    return [self.completionBlocks objectForKey:@(status)];
}

- (BOOL)setStatus:(NSUInteger)status animated:(BOOL)animated {
    WLSignupStepCompletionBlock block = [self completionBlockForStatus:status];
    if (!block) return NO;
    UINavigationController* navigationController = self.navigationController;
    WLSignupStepViewController *controller = block();
    if ([navigationController.viewControllers containsObject:controller]) {
        [navigationController popToViewController:controller animated:animated];
    } else {
        [navigationController pushViewController:controller animated:animated];
    }
    return YES;
}

- (BOOL)setSuccessStatusAnimated:(BOOL)animated {
    return [self setStatus:WLSignupStepStatusSuccess animated:animated];
}

- (BOOL)setFailureStatusAnimated:(BOOL)animated {
    return [self setStatus:WLSignupStepStatusFailure animated:animated];
}

- (BOOL)setCancelStatusAnimated:(BOOL)animated {
    return [self setStatus:WLSignupStepStatusCancel animated:animated];
}

- (IBAction)success:(id)sender {
    [self setSuccessStatusAnimated:NO];
}

- (IBAction)failure:(id)sender {
    [self setFailureStatusAnimated:NO];
}

- (IBAction)cancel:(id)sender {
    if (![self setCancelStatusAnimated:YES]) {
        [self.navigationController popViewControllerAnimated:NO];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
