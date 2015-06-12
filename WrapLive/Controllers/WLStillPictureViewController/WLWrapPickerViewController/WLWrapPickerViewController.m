//
//  WLWrapPickerViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapPickerViewController.h"
#import "WLBasicDataSource.h"
#import "WLToast.h"

@interface WLWrapPickerViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *wrapNameTextField;
@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingTextFieldConstraint;

@end

@implementation WLWrapPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setSelectionBlock:^(WLWrap* wrap) {
        [weakSelf.delegate wrapPickerViewController:weakSelf didSelectWrap:wrap];
    }];
    
    self.wrapNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.wrapNameTextField.placeholder attributes:@{NSForegroundColorAttributeName:[UIColor WL_grayLighter]}];
    self.dataSource.items = [[WLUser currentUser] sortedWraps];
    
    if (self.wrap) {
        NSUInteger index = [(NSOrderedSet*)self.dataSource.items indexOfObject:self.wrap];
        if (index != NSNotFound) {
            [self.dataSource.collectionView layoutIfNeeded];
            [self.dataSource.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
        }
    } else {
        self.leadingTextFieldConstraint.constant = 8;
        [self.wrapNameTextField.superview setNeedsLayout];
        [self.wrapNameTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    }
    
    [self.view addGestureRecognizer:self.dataSource.collectionView.panGestureRecognizer];
}

- (void)animatePresenting {
    self.view.backgroundColor = [UIColor clearColor];
    for (UIView *view in self.view.subviews) {
        view.transform = CGAffineTransformMakeTranslation(0, -355);
    }
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        for (UIView *view in self.view.subviews) {
            view.transform = CGAffineTransformIdentity;
        }
        self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)createNewWrap:(id)sender {
    [self.wrapNameTextField becomeFirstResponder];
}

- (IBAction)saveNewWrap:(id)sender {
    [WLToast showWithMessage:@"It is not implemented yet."];
}

- (void)hide {
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        for (UIView *view in self.view.subviews) {
            view.transform = CGAffineTransformMakeTranslation(0, -355);
        }
        self.view.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        for (UIView *view in self.view.subviews) {
            view.transform = CGAffineTransformIdentity;
        }
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
}

- (IBAction)hide:(id)sender {
    if (self.wrapNameTextField.isFirstResponder) {
        [self.wrapNameTextField resignFirstResponder];
        return;
    }
    [self.delegate wrapPickerViewControllerDidCancel:self];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

// MARK: - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.leadingTextFieldConstraint.constant = 8;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.wrapNameTextField.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.leadingTextFieldConstraint.constant = 52;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.wrapNameTextField.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    self.trailingTextFieldConstraint.constant = textField.text.nonempty ? 52 : 8;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.wrapNameTextField.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

@end
