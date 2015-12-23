//
//  WLConfirmView.m
//  meWrap
//
//  Created by Yura Granchenko on 12/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLConfirmView.h"
#import "WLToast.h"

@interface WLConfirmView ()

@property (strong, nonatomic) Authorization* authorization;

@property (strong, nonatomic) ObjectBlock success;
@property (strong, nonatomic) Block cancel;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation WLConfirmView

+ (void)showInView:(UIView *)view authorization:(Authorization *)authorization success:(ObjectBlock)succes cancel:(Block)cancel {
    [[WLConfirmView loadFromNib:@"WLConfirmView"] showInView:view authorization:authorization success:succes cancel:cancel];
}

- (void)showInView:(UIView *)view authorization:(Authorization *)authorization success:(ObjectBlock)success cancel:(Block)cancel {
    self.frame = view.frame;
    self.authorization = authorization;
    [view addSubview:self];
    self.backgroundColor = [UIColor clearColor];
    self.contentView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    self.contentView.alpha = 0.0f;
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.contentView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75f];
        weakSelf.contentView.alpha = 1.0f;
    } completion:^(BOOL finished) {
    }];
    [self confirmationSuccess:success cancel:cancel];
}

- (void)setAuthorization:(Authorization *)authorization {
    _authorization = authorization;
    self.emailLabel.text = [authorization email];
    self.phoneLabel.text = [authorization fullPhoneNumber];
}

- (void)confirmationSuccess:(ObjectBlock)success cancel:(Block)cancel {
    self.success = success;
    self.cancel = cancel;
}

- (void)hide {
    __weak typeof(self)weakSelf = self;
    [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        weakSelf.contentView.transform = CGAffineTransformMakeScale(0.5, 0.5);
        weakSelf.backgroundColor = [UIColor clearColor];
        weakSelf.contentView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [weakSelf removeFromSuperview];
    }];
}

- (IBAction)cancel:(id)sender {
    if (self.cancel) self.cancel();
    [self hide];
}

- (IBAction)confirm:(id)sender {
    if (self.success) self.success(self.authorization);
    [self hide];
}

@end

@interface WLEditingConfirmView () <UITextViewDelegate>

@end

@implementation WLEditingConfirmView : WLConfirmView

+ (void)showInView:(UIView *)view withContent:(NSString *)content success:(ObjectBlock)succes cancel:(Block)cancel {
     [[WLEditingConfirmView loadFromNib:@"WLEditingConfirmView"] showInView:view withContent:(NSString *)content success:succes cancel:cancel];
}

static CGFloat WLMessageLimit = 280;

- (void)showInView:(UIView *)view withContent:(NSString *)content success:(ObjectBlock)success cancel:(Block)cancel {
    [[Keyboard keyboard] addReceiver:self];
    [self.contentTextView determineHyperLink:content];
    self.contentTextView.delegate = self;
    [super showInView:view authorization:nil success:success cancel:cancel];
}

- (IBAction)confirm:(id)sender {
    if (self.success) self.success(self.contentTextView.text);
    [self hide];
}

- (void)keyboardWillShow:(Keyboard*)keyboard {
    [UIView animateWithDuration:0.25 animations:^{
        self.keyboardPrioritizer.constant -= keyboard.height/2;
        [self layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(Keyboard*)keyboard {
    [UIView animateWithDuration:0.25 animations:^{
        self.keyboardPrioritizer.constant += keyboard.height/2;
        [self layoutIfNeeded];
    }];
}

// MARK: - UITextViewDelegate


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString* resultString = [textView.text stringByReplacingCharactersInRange:range withString:text];
    return resultString.length <= WLMessageLimit;
}

@end
