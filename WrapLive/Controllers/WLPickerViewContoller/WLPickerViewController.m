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
#import "UIView+Shorthand.h"
#import "WLButton.h"
#import "WLPickerViewController.h"
#import "WLUser+Extended.h"
#import "WLWrap+Extended.h"
#import "WLWrapCell.h"
#import "NSString+Additions.h"
#import "UIView+GestureRecognizing.h"
#import "WLStillPictureMode.h"

static NSString *const WLPickerViewCell = @"WLPickerViewCell";
static NSString *const WLCreateWrapCell = @"WLCreateWrapCell";

@interface WLPickerViewController () <UIGestureRecognizerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSOrderedSet *entries;
@property (strong, nonatomic) WLWrap *selectedWrap;
@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation WLPickerViewController

- (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate {
    self = [super init];
    if (self) {
        NSOrderedSet *wraps = [[WLUser currentUser] sortedWraps];
        [self setWrap:wrap];
        [self setEntries:wraps];
        [self setDelegate:delegate];
    }
    return self;
}

+ (BOOL)isEmbeddedDefaultValue {
    return YES;
}

- (void)addEmbeddingConstraintsToContentView:(UIView *)contentView inView:(UIView *)view {
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeBottom multiplier:1 constant:WLStillPictureBottomViewHeight]];
    [contentView addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:contentView.bounds.size.height]];
}

- (void)embeddingViewTapped:(UITapGestureRecognizer *)sender {
    if([self.delegate respondsToSelector:@selector(pickerViewControllerDidCancel:)]) {
        [self.delegate pickerViewControllerDidCancel:self];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    self.tapGesture.delegate = self;
    [self.pickerView addGestureRecognizer:self.tapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSInteger index = [self.entries indexOfObject:self.wrap];
    [self.pickerView selectRow:index + 1 inComponent:0 animated:YES];
}

- (void)dealloc {
    [self.pickerView removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    [_pickerView reloadAllComponents];
}

- (void)setEntries:(NSOrderedSet *)entries {
    _entries = entries;
    [_pickerView reloadAllComponents];
}

- (void)setDelegate:(id<WLPickerViewDelegate>)delegate {
    _delegate = delegate;
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return NSINTEGER_DEFINED;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.entries count] + NSINTEGER_DEFINED;
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    if (!row) {
        return [UIView loadFromNibNamed:WLCreateWrapCell ownedBy:self];
    } else {
        WLWrap *wrap = self.entries[row - 1];
        WLWrapCell *pickerCell = [WLWrapCell loadFromNibNamed:WLPickerViewCell];
        pickerCell.entry = wrap;
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
    self.selectedWrap = self.entries[row -1];
    if ([self.delegate respondsToSelector:@selector(pickerViewController:didSelectWrap:)]) {
        [self.delegate pickerViewController:self didSelectWrap:self.selectedWrap];
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

@end