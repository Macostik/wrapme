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
#import "WLButton.h"
#import "WLKeyboard.h"
#import "UIScrollView+Additions.h"

@interface WLWrapPickerDataSource : WLBasicDataSource

@property (strong, nonatomic) WLBlock didEndScrollingAnimationBlock;

@end

@implementation WLWrapPickerDataSource

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    targetContentOffset->y = roundf(targetContentOffset->y / self.itemSize.height) * self.itemSize.height;
    [super scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.didEndScrollingAnimationBlock) {
        self.didEndScrollingAnimationBlock();
        self.didEndScrollingAnimationBlock = nil;
    }
}

@end

@interface WLWrapPickerViewController () <WLAddWrapPickerViewDelegate>

@property (strong, nonatomic) IBOutlet WLWrapPickerDataSource *dataSource;

@end

@implementation WLWrapPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat itemHeight = self.dataSource.itemSize.height;
    
    self.dataSource.collectionView.contentInset = self.dataSource.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(itemHeight, 0, itemHeight, 0);
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setSelectionBlock:^(WLWrap* wrap) {
        NSUInteger index = [(NSOrderedSet*)weakSelf.dataSource.items indexOfObject:wrap];
        if (index != NSNotFound && weakSelf.dataSource.collectionView.contentOffset.y != index * itemHeight) {
            [weakSelf.dataSource.collectionView setContentOffset:CGPointMake(0, index * itemHeight) animated:YES];
        } else {
            [weakSelf.delegate wrapPickerViewController:weakSelf didSelectWrap:wrap];
        }
    }];
    
    [self.dataSource setItemSizeBlock:^CGSize(id item, NSUInteger index) {
        return CGSizeMake(weakSelf.dataSource.collectionView.width, itemHeight);
    }];
    
    self.dataSource.items = [[WLUser currentUser] sortedWraps];
    
    if (self.wrap) {
        NSUInteger index = [(NSOrderedSet*)self.dataSource.items indexOfObject:self.wrap];
        if (index != NSNotFound) {
            [self.dataSource.collectionView layoutIfNeeded];
            [self.dataSource.collectionView setContentOffset:CGPointMake(0, index * itemHeight) animated:NO];
        }
    }
    
    [self.view addGestureRecognizer:self.dataSource.collectionView.panGestureRecognizer];
}

- (BOOL)shouldResizeUsingScreenBounds {
    return NO;
}

- (void)hide {
    [self.view endEditing:YES];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (IBAction)hide:(id)sender {
    if ([WLKeyboard keyboard].isShow) {
        [self.view endEditing:NO];
    } else {
        [self.delegate wrapPickerViewControllerDidCancel:self];
    }
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)addWrapPickerView:(WLAddWrapPickerView *)view didAddWrap:(WLWrap *)wrap {
    [self.delegate wrapPickerViewController:self didSelectWrap:wrap];
}

- (BOOL)addWrapPickerViewShouldBeginEditing:(WLAddWrapPickerView *)view {
    BOOL shouldBeginEditing = self.dataSource.collectionView.contentOffset.y == -self.dataSource.itemSize.height;
    if (!shouldBeginEditing) {
        self.dataSource.didEndScrollingAnimationBlock = ^{
            [view.wrapNameTextField becomeFirstResponder];
        };
        [self.dataSource.collectionView setContentOffset:CGPointMake(0, -self.dataSource.itemSize.height) animated:YES];
    }
    return shouldBeginEditing;
}

- (void)addWrapPickerViewDidBeginEditing:(WLAddWrapPickerView *)view {
}

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    CGFloat adjustment = keyboardHeight - (self.view.height - CGRectGetMaxY(self.dataSource.collectionView.frame) - 10);
    return MAX(0, adjustment);
}

@end

@implementation WLWrapPickerCollectionViewLayout : UICollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [[super layoutAttributesForElementsInRect:rect] map:^id(UICollectionViewLayoutAttributes *attributes) {
        return [self adjustAttributes:attributes];
    }];
}

- (UICollectionViewLayoutAttributes*)adjustAttributes:(UICollectionViewLayoutAttributes*)attributes {
    CGFloat centerY = attributes.frame.origin.y - self.collectionView.contentOffset.y + attributes.frame.size.height/2;
    CGFloat size = self.collectionView.height/2;
    CGFloat offset = (centerY - size)/size;
    attributes.transform3D = CATransform3DMakeRotation((M_PI / 2.7) * offset, 1, 0, 0);
    attributes.transform3D = CATransform3DTranslate(attributes.transform3D, 0, 0, 10 * ABS(offset));
    attributes.alpha = 1 - ABS(offset);
    return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self adjustAttributes:[super layoutAttributesForItemAtIndexPath:indexPath]];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    return [self adjustAttributes:[super layoutAttributesForSupplementaryViewOfKind:elementKind atIndexPath:indexPath]];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

@end

@interface WLAddWrapPickerView () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *wrapNameTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingTextFieldConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *createButtonCenterConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *createButtonLeadingConstraint;

@end

@implementation WLAddWrapPickerView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.wrapNameTextField.placeholder = WLLS(@"new_wrap");
}

- (void)setup:(id)entry {
    if (!entry) {
        [self.wrapNameTextField becomeFirstResponder];
    }
}

// MARK: - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.delegate addWrapPickerViewDidBeginEditing:self];
    self.wrapNameTextField.placeholder = WLLS(@"what_is_new_wrap_about");
    self.createButtonCenterConstraint.priority = UILayoutPriorityDefaultLow;
    self.createButtonLeadingConstraint.priority = UILayoutPriorityDefaultHigh;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.wrapNameTextField.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.wrapNameTextField.placeholder = WLLS(@"new_wrap");
    self.createButtonCenterConstraint.priority = UILayoutPriorityDefaultHigh;
    self.createButtonLeadingConstraint.priority = UILayoutPriorityDefaultLow;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.wrapNameTextField.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
    }];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return [self.delegate addWrapPickerViewShouldBeginEditing:self];
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    self.trailingTextFieldConstraint.constant = textField.text.nonempty ? 52 : 8;
    [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.wrapNameTextField.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)createNewWrap:(id)sender {
    [self.wrapNameTextField becomeFirstResponder];
}

- (IBAction)saveNewWrap:(WLButton*)sender {
    
    NSString *name = self.wrapNameTextField.text;
    if (!name.nonempty) {
        [WLToast showWithMessage:WLLS(@"wrap_name_cannot_be_blank")];
        return;
    }
    
    [self.wrapNameTextField resignFirstResponder];
    WLWrap *wrap = [WLWrap wrap];
    wrap.name = name;
    [wrap notifyOnAddition:nil];
    [self.delegate addWrapPickerView:self didAddWrap:wrap];
    [WLUploadingQueue upload:[WLUploading uploading:wrap] success:^(id object) {
    } failure:^(NSError *error) {
        if (![error isNetworkError]) {
            [error show];
            [wrap remove];
        }
    }];
}

@end
