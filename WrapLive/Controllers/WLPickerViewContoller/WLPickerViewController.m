//
//  WLPickerViewController.m
//  WrapLive
//
//  Created by Yura Granchenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "NSObject+NibAdditions.h"
#import "UIFont+CustomFonts.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLButton.h"
#import "WLPickerViewController.h"
#import "WLWrapCell.h"
#import "UIView+GestureRecognizing.h"
#import "WLStillPictureViewController.h"

static NSString *const WLPickerViewCell = @"WLPickerViewCell";
static NSString *const WLCreateWrapCell = @"WLCreateWrapCell";

@interface WLPickerViewController () <UIGestureRecognizerDelegate, UIPickerViewDataSource, UIPickerViewDelegate, WLEntryNotifyReceiver>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSOrderedSet *wraps;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation WLPickerViewController

- (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate {
    self = [super init];
    if (self) {
        self.wrap = wrap;
        self.wraps = [[WLUser currentUser] sortedWraps];
        self.delegate = delegate;
    }
    return self;
}

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)addEmbeddingConstraintsToContentView:(UIView *)contentView inView:(UIView *)view {
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    WLStillPictureViewController *controller = (id)self.presentingViewController;
    CGFloat bottomInset;
    if ([controller isKindOfClass:[WLStillPictureViewController class]] && controller.cameraNavigationController.viewControllers.count == 1) {
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        bottomInset = screenSize.height - screenSize.width / WLStillPictureCameraViewAspectRatio;
    } else {
        bottomInset = WLStillPictureBottomViewHeight;
    }
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:bottomInset]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:contentView.bounds.size.height]];
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    if (self.delegate) {
        if([self.delegate respondsToSelector:@selector(pickerViewControllerDidCancel:)]) {
            [self.delegate pickerViewControllerDidCancel:self];
        }
    } else {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.delegate = self;
    [self.pickerView addGestureRecognizer:self.tapGesture];
    [[WLWrap notifier] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_pickerView reloadAllComponents];
    NSInteger index = [self.wraps indexOfObject:self.wrap];
    [self.pickerView selectRow:index + 1 inComponent:0 animated:YES];
}

- (void)dealloc {
    [self.pickerView removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

- (void)setWraps:(NSOrderedSet *)wraps {
    _wraps = wraps;
    if (self.isViewLoaded) [_pickerView reloadAllComponents];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return NSINTEGER_DEFINED;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.wraps count] + NSINTEGER_DEFINED;
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    if (!row) {
        UIView *createCell = [UIView loadFromNibNamed:WLCreateWrapCell ownedBy:self];
        createCell.width = self.pickerView.width;
        return createCell;
    } else {
        WLWrapCell *pickerCell = [WLWrapCell loadFromNibNamed:WLPickerViewCell];
        pickerCell.entry = self.wraps[row - 1];
        return pickerCell;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 44.0f;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return self.view.width;
}

#pragma mark - WLPickerViewController Action

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (!row) return;
    if ([self.delegate respondsToSelector:@selector(pickerViewController:didSelectWrap:)]) {
        [self.delegate pickerViewController:self didSelectWrap:self.wraps[row - 1]];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (void)tapGesture:(UITapGestureRecognizer *)gesture {
    UIView *createWrapCell = [self.pickerView viewForRow:0 forComponent:0];
    CGPoint touchPoint = [gesture locationInView:createWrapCell];
    if (CGRectContainsPoint(createWrapCell.frame, touchPoint)) {
        if([self.delegate respondsToSelector:@selector(pickerViewControllerNewWrapClicked:)]) {
            [self.delegate pickerViewControllerNewWrapClicked:self];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

// MARK: - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier *)notifier wrapAdded:(WLWrap *)wrap {
    self.wraps = [[WLUser currentUser] sortedWraps];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapUpdated:(WLWrap *)wrap {
    [_pickerView reloadAllComponents];
}

- (void)notifier:(WLEntryNotifier *)notifier wrapDeleted:(WLWrap *)wrap {
    self.wraps = [[WLUser currentUser] sortedWraps];
}

@end