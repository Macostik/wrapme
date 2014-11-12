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
#import "WLWrap.h"
#import "WLWrapCell.h"

@interface WLPickerViewController ()

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSArray *entries;
@property (strong, nonatomic) WLWrapBlock selectBlock;

@end

@implementation WLPickerViewController

- (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate {
    self = [super init];
    if (self) {
        NSArray *wrapsArray = [[[WLUser currentUser] sortedWraps] array];
        [self setWrap:wrap];
        [self setEntries:wrapsArray];
        [self setDelegate:delegate];
    }
    return self;
}

+ (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate selectionBlock:(WLWrapBlock)block {
    WLPickerViewController *pickerViewController = [[self alloc] initWithWrap:wrap delegate:delegate];
    pickerViewController.selectBlock = block;
    return pickerViewController;
}

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    NSInteger index = [self.entries indexOfObject:_wrap];
    [self.pickerView selectRow:index inComponent:0 animated:YES];
}

- (void)setEntries:(NSArray *)entries {
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
    return [self.entries count];
}

#pragma mark - UIPickerViewDelegate

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    WLWrap *wrap = self.entries[row];
    WLWrapCell *pickerCell = [WLWrapCell loadFromNibNamed:@"WLPickerViewCell"];
    pickerCell.width = self.view.width;
    pickerCell.entry = wrap;
    
    return pickerCell;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 44.0f;
}

#pragma mark - WLPickerViewController Action

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (self.selectBlock) {
        self.selectBlock(self.entries[row]);
    }
}

- (IBAction)newWrapClick:(id)sender {
    if([self.delegate respondsToSelector:@selector(pickerViewController: newWrapClick:)]) {
        [self.delegate pickerViewController:self newWrapClick:sender];
    }
}

- (IBAction)doneClick:(id)sender {
    if([self.delegate respondsToSelector:@selector(pickerViewController: doneClick:)]) {
        [self.delegate pickerViewController:self doneClick:sender];
    }
}

@end

