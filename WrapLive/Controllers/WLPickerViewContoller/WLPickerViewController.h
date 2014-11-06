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

@class WLPickerViewController;

@protocol WLPickerViewDelegate <NSObject>
@optional
- (void)pickerViewController:(WLPickerViewController *)pickerViewController doneClick:(UIButton *)sender;

@end

@interface WLPickerViewController : UIViewController 

@property (weak, nonatomic) IBOutlet UIView *contenView;
@property (strong, nonatomic) WLWrap *wrap;
@property (assign, nonatomic) id <WLPickerViewDelegate> delegate;

- (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate;
+ (instancetype)initWithWrap:(WLWrap *)wrap delegate:(id)delegate selectionBlock:(WLWrapBlock)block;

@end
