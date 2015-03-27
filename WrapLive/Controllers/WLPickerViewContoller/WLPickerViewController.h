//
//  WLPickerViewController.h
//  WrapLive
//
//  Created by Yura Granchenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLWrap;
@class WLPickerViewController;

@protocol WLPickerViewDelegate <NSObject>

@optional
- (void)pickerViewControllerNewWrapClicked:(WLPickerViewController *)pickerViewController;

- (void)pickerViewController:(WLPickerViewController *)pickerViewController didSelectWrap:(WLWrap *)wrap;

- (void)pickerViewControllerDidCancel:(WLPickerViewController *)pickerViewController;

@end

@interface WLPickerViewController : WLBaseViewController

@property (weak, nonatomic) WLWrap *wrap;

@property (weak, nonatomic) id <WLPickerViewDelegate> delegate;

- (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate;

@end
