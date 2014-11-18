//
//  WLPickerViewController.h
//  WrapLive
//
//  Created by Yura Granchenko on 11/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefinedBlocks.h"
#import "WLActionViewController.h"
#import "WLWrap.h"

@class WLPickerViewController;

@protocol WLPickerViewDelegate <NSObject>
@optional
- (void)pickerViewController:(WLPickerViewController *)pickerViewController newWrapClick:(UIView *)sender;
- (void)pickerViewController:(WLPickerViewController *)pickerViewController tapBySelectedWrap:(WLWrap *)wrap;

@end

@interface WLPickerViewController : UIViewController 

@property (strong, nonatomic) WLWrap *wrap;
@property (assign, nonatomic) id <WLPickerViewDelegate> delegate;

- (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate;
+ (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate selectionBlock:(WLWrapBlock)block;

@end
