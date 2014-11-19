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

static NSString *const WLPickerViewCell = @"WLPickerViewCell";
static NSString *const WLCreateWrapCell = @"WLCreateWrapCell";

@interface WLPickerViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSOrderedSet *entries;
@property (strong, nonatomic) WLWrapBlock selectBlock;
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

+ (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate selectionBlock:(WLWrapBlock)block {
    WLPickerViewController *pickerViewController = [[self alloc] initWithWrap:wrap delegate:delegate];
    pickerViewController.selectBlock = block;
    return pickerViewController;
}

- (void)viewDidLoad {
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
    WLWrapCell *pickerCell = nil;
    if (!row) {
        pickerCell = [UIView loadFromNibNamed:WLCreateWrapCell ownedBy:self];
        pickerCell.width = self.view.width;
    } else {
        WLWrap *wrap = self.entries[row - 1];
        pickerCell = [WLWrapCell loadFromNibNamed:WLPickerViewCell];
        pickerCell.width = self.view.width;
        pickerCell.entry = wrap;
    }
    return pickerCell;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 44.0f;
}

#pragma mark - WLPickerViewController Action

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (!row)return;
    if (self.selectBlock) {
        self.selectedWrap = self.entries[row -1];
        self.selectBlock(self.entries[row - 1]);
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (void)tapGesture:(UITapGestureRecognizer *)gesture {
    UIView *createWrapCell = [self.pickerView viewForRow:0 forComponent:0];
    CGPoint touchPoint = [gesture locationInView:createWrapCell];
    if (CGRectContainsPoint(createWrapCell.frame, touchPoint)) {
        if([self.delegate respondsToSelector:@selector(pickerViewController: newWrapClick:)]) {
            [self.delegate pickerViewController:self newWrapClick:createWrapCell];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(pickerViewController:tapBySelectedWrap:)]) {
            [self.delegate pickerViewController:self tapBySelectedWrap:self.selectedWrap];
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end