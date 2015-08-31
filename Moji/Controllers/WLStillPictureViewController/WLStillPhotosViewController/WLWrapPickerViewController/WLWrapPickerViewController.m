//
//  WLWrapPickerViewController.m
//  moji
//
//  Created by Ravenpod on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWrapPickerViewController.h"
#import "StreamDataSource.h"
#import "WLToast.h"
#import "WLButton.h"
#import "WLKeyboard.h"
#import "UIScrollView+Additions.h"
#import "WLLayoutPrioritizer.h"

@interface WLWrapPickerDataSource : StreamDataSource

@property (strong, nonatomic) WLBlock didEndScrollingAnimationBlock;

@end

@implementation WLWrapPickerDataSource

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    targetContentOffset->y = roundf(targetContentOffset->y / self.autogeneratedMetrics.size) * self.autogeneratedMetrics.size;
    [super scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.didEndScrollingAnimationBlock) {
        self.didEndScrollingAnimationBlock();
        self.didEndScrollingAnimationBlock = nil;
    }
}

@end

@interface WLWrapPickerViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet WLWrapPickerDataSource *dataSource;

@property (weak, nonatomic) IBOutlet UITextField *wrapNameTextField;

@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *editingPrioritizer;

@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *savingPrioritizer;

@end

@implementation WLWrapPickerViewController

- (void)dealloc {
    [self.dataSource.streamView removeObserver:self forKeyPath:@"contentOffset" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak StreamDataSource *dataSource = self.dataSource;
    __weak StreamView *streamView = dataSource.streamView;
    
    CGFloat itemHeight = dataSource.autogeneratedMetrics.size;
    
    streamView.contentInset = streamView.scrollIndicatorInsets = UIEdgeInsetsMake(itemHeight, 0, itemHeight, 0);
    
    __weak typeof(self)weakSelf = self;
    [dataSource.autogeneratedMetrics setSelectionBlock:^(StreamItem *item, WLWrap *wrap) {
        NSUInteger index = [(NSOrderedSet*)dataSource.items indexOfObject:wrap];
        if (index != NSNotFound && streamView.contentOffset.y != index * itemHeight) {
            [streamView setContentOffset:CGPointMake(0, index * itemHeight) animated:YES];
        } else {
            run_after_asap(^{
                [weakSelf.delegate wrapPickerViewControllerDidFinish:weakSelf];
            });
        }
    }];
    
    dataSource.items = [[WLUser currentUser] sortedWraps];
    
    if (self.wrap) {
        NSUInteger index = [(NSOrderedSet*)dataSource.items indexOfObject:self.wrap];
        if (index != NSNotFound) {
            [streamView setContentOffset:CGPointMake(0, index * itemHeight) animated:NO];
        }
    }
    
    [WLWrap notifyReceiverOwnedBy:self setupBlock:^(WLEntryNotifyReceiver *receiver) {
        receiver.didAddBlock = receiver.didDeleteBlock = receiver.didUpdateBlock = ^ (WLWrap *wrap) {
            dataSource.items = [[WLUser currentUser] sortedWraps];
        };
    }];
    
    [self.view addGestureRecognizer:streamView.panGestureRecognizer];
    
    [streamView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    
    self.wrapNameTextField.placeholder = WLLS(@"new_moji");
    if (self.wrap == nil) {
        self.editingPrioritizer.defaultState = NO;
        [self.wrapNameTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
    }
}

- (BOOL)shouldResizeViewWithScreenBounds {
    return NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        NSOrderedSet *wraps = (NSOrderedSet*)self.dataSource.items;
        CGFloat offset = self.dataSource.streamView.contentOffset.y;
        if (wraps.nonempty && offset >= 0) {
            NSInteger index = roundf(offset / self.dataSource.autogeneratedMetrics.size);
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
    if (self.wrapNameTextField.isFirstResponder) {
        [self.wrapNameTextField resignFirstResponder];
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

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    CGFloat adjustment = keyboardHeight - (self.view.height - CGRectGetMaxY(self.dataSource.streamView.frame) - 10);
    return MAX(0, adjustment);
}

// MARK: - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.wrapNameTextField.placeholder = WLLS(@"what_is_new_moji_about");
    [self.editingPrioritizer setDefaultState:NO animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.wrapNameTextField.placeholder = WLLS(@"new_moji");
    [self.editingPrioritizer setDefaultState:YES animated:YES];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    BOOL shouldBeginEditing = self.dataSource.streamView.contentOffset.y == -self.dataSource.autogeneratedMetrics.size;
    if (!shouldBeginEditing) {
        self.dataSource.didEndScrollingAnimationBlock = ^{
            [textField becomeFirstResponder];
        };
        [self.dataSource.streamView setContentOffset:CGPointMake(0, -self.dataSource.autogeneratedMetrics.size) animated:YES];
    }
    return shouldBeginEditing;
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    NSString *text = textField.text;
    if (text.length > WLProfileNameLimit) {
        text = textField.text = [text substringToIndex:WLProfileNameLimit];
    }
    [self.savingPrioritizer setDefaultState:!text.nonempty animated:YES];
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
    [self.delegate wrapPickerViewController:self didSelectWrap:wrap];
    [self.delegate wrapPickerViewControllerDidFinish:self];
    [WLUploadingQueue upload:[WLUploading uploading:wrap] success:^(id object) {
    } failure:^(NSError *error) {
        if (![error isNetworkError]) {
            [error show];
            [wrap remove];
        }
    }];
}

@end

@implementation WLWrapPickerCollectionViewLayout : UICollectionViewFlowLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return [[super layoutAttributesForElementsInRect:rect] map:^id(UICollectionViewLayoutAttributes *attributes) {
        return [self adjustAttributes:attributes];
    }];
}

- (UICollectionViewLayoutAttributes*)adjustAttributes:(UICollectionViewLayoutAttributes*)attributes {
#warning implement stream view items transform
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
