//
//  WLWrapPickerViewController.h
//  moji
//
//  Created by Ravenpod on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLWrapPickerViewController;
@class WLWrap;

@protocol WLWrapPickerViewControllerDelegate <NSObject>

- (void)wrapPickerViewController:(WLWrapPickerViewController*)controller didSelectWrap:(WLWrap*)wrap;

- (void)wrapPickerViewControllerDidFinish:(WLWrapPickerViewController*)controller;

- (void)wrapPickerViewControllerDidCancel:(WLWrapPickerViewController*)controller;

@end

@interface WLWrapPickerViewController : WLBaseViewController

@property (nonatomic, weak) id <WLWrapPickerViewControllerDelegate> delegate;

@property (weak, nonatomic) WLWrap* wrap;

- (void)showInViewController:(UIViewController*)controller animated:(BOOL)animated;

- (void)hide;

@end

@interface WLWrapPickerCollectionViewLayout : UICollectionViewFlowLayout

@end
