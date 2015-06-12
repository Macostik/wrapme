//
//  WLWrapPickerViewController.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLWrapPickerViewController;
@class WLWrap;

@protocol WLWrapPickerViewControllerDelegate <NSObject>

- (void)wrapPickerViewController:(WLWrapPickerViewController*)controller didSelectWrap:(WLWrap*)wrap;

- (void)wrapPickerViewControllerDidCancel:(WLWrapPickerViewController*)controller;

@end

@interface WLWrapPickerViewController : UIViewController

@property (nonatomic, weak) id <WLWrapPickerViewControllerDelegate> delegate;

@property (weak, nonatomic) WLWrap* wrap;

- (void)animatePresenting;

- (void)hide;

@end
