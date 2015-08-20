//
//  WLWrapPickerViewController.m
//  moji
//
//  Created by Ravenpod on 6/12/15.
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

@property (nonatomic) BOOL keyboardHandled;

@end

@implementation WLWrapPickerViewController

- (void)dealloc {
    [self.dataSource.collectionView removeObserver:self forKeyPath:@"contentOffset" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad:NO];
    
    CGFloat itemHeight = self.dataSource.itemSize.height;
    
    self.dataSource.collectionView.contentInset = self.dataSource.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(itemHeight, 0, itemHeight, 0);
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setSelectionBlock:^(WLWrap* wrap) {
        NSUInteger index = [(NSOrderedSet*)weakSelf.dataSource.items indexOfObject:wrap];
        if (index != NSNotFound && weakSelf.dataSource.collectionView.contentOffset.y != index * itemHeight) {
            [weakSelf.dataSource.collectionView setContentOffset:CGPointMake(0, index * itemHeight) animated:YES];
        } else {
            run_after_asap(^{
                [weakSelf.delegate wrapPickerViewControllerDidFinish:weakSelf];
            });
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
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        receiver.didAddBlock = receiver.didDeleteBlock = receiver.didUpdateBlock = ^ (WLWrap *wrap) {
            weakSelf.dataSource.items = [[WLUser currentUser] sortedWraps];
        };
    }];
    
    [self.view addGestureRecognizer:self.dataSource.collectionView.panGestureRecognizer];
    
    [self.dataSource.collectionView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        NSOrderedSet *wraps = (NSOrderedSet*)self.dataSource.items;
        CGFloat offset = self.dataSource.collectionView.contentOffset.y;
        if (wraps.nonempty && offset >= 0) {
            NSInteger index = roundf(offset / self.dataSource.itemSize.height);
            WLWrap *wrap = [wraps tryAt:index];
            if (wrap && wrap != self.wrap) {
                self.wrap = wrap;
                [self.delegate wrapPickerViewController:self didSelectWrap:wrap];
            }
        }
    }
}

- (void)showInViewController:(UIViewController*)controller animated:(BOOL)animated {
    self.view.frame = controller.view.bounds;
    [controller addChildViewController:self];
    [self viewWillAppear:animated];
    [controller.view addSubview:self.view];
    [self viewDidAppear:animated];
}

- (void)hide {
    [self.view endEditing:YES];
    [self viewWillDisappear:NO];
    [self.view removeFromSuperview];
    [self viewDidDisappear:NO];
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

// MARK: - WLAddWrapPickerViewDelegate

- (BOOL)addWrapPickerViewShouldShowKeyboard:(WLAddWrapPickerView *)view {
    BOOL shouldShowKeyboard = self.wrap == nil && !self.keyboardHandled;
    self.keyboardHandled = YES;
    return shouldShowKeyboard;
}

- (void)addWrapPickerView:(WLAddWrapPickerView *)view didAddWrap:(WLWrap *)wrap {
    [self.delegate wrapPickerViewController:self didSelectWrap:wrap];
    [self.delegate wrapPickerViewControllerDidFinish:self];
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
    
    self.wrapNameTextField.placeholder = WLLS(@"new_moji");
    if ([self.delegate addWrapPickerViewShouldShowKeyboard:self]) {
        self.createButtonCenterConstraint.priority = UILayoutPriorityDefaultLow;
        self.createButtonLeadingConstraint.priority = UILayoutPriorityDefaultHigh;
        [self.wrapNameTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    }
}

// MARK: - UITextFieldDelegate

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    BOOL changed = NO;
    UILayoutPriority centerPriority = editing ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;
    UILayoutPriority leadingPriority = editing ? UILayoutPriorityDefaultHigh : UILayoutPriorityDefaultLow;
    if (self.createButtonCenterConstraint.priority != centerPriority) {
        self.createButtonCenterConstraint.priority = centerPriority;
        changed = YES;
    }
    if (self.createButtonLeadingConstraint.priority != leadingPriority) {
        self.createButtonLeadingConstraint.priority = leadingPriority;
        changed = YES;
    }
    if (changed) {
        if (animated) {
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [self.wrapNameTextField.superview layoutIfNeeded];
            } completion:^(BOOL finished) {
            }];
        } else {
            [self.wrapNameTextField.superview layoutIfNeeded];
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.delegate addWrapPickerViewDidBeginEditing:self];
    self.wrapNameTextField.placeholder = WLLS(@"what_is_new_moji_about");
    [self setEditing:YES animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.wrapNameTextField.placeholder = WLLS(@"new_moji");
    [self setEditing:NO animated:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return [self.delegate addWrapPickerViewShouldBeginEditing:self];
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    NSString *text = textField.text;
    if (text.length > WLProfileNameLimit) {
        text = textField.text = [text substringToIndex:WLProfileNameLimit];
    }
    CGFloat constant = text.nonempty ? 52 : 8;
    if (self.trailingTextFieldConstraint.constant != constant) {
        self.trailingTextFieldConstraint.constant = constant;
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self.wrapNameTextField.superview layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)createNewWrap:(id)sender {
    [self.wrapNameTextField becomeFirstResponder];
}

- (IBAction)saveNewWrap:(WLButton*)sender {
    
    NSString *name = [self.wrapNameTextField.text trim];
    if (!name.nonempty) {
        [WLToast showWithMessage:WLLS(@"moji_name_cannot_be_blank")];
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
