//
//  WLWrapPickerViewController.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"
#import "WLEntryReusableView.h"

@class WLWrapPickerViewController;
@class WLWrap;

@protocol WLWrapPickerViewControllerDelegate <NSObject>

- (void)wrapPickerViewController:(WLWrapPickerViewController*)controller didSelectWrap:(WLWrap*)wrap;

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

@class WLAddWrapPickerView;

@protocol WLAddWrapPickerViewDelegate <NSObject>

- (BOOL)addWrapPickerViewShouldShowKeyboard:(WLAddWrapPickerView*)view;

- (BOOL)addWrapPickerViewShouldBeginEditing:(WLAddWrapPickerView*)view;

- (void)addWrapPickerViewDidBeginEditing:(WLAddWrapPickerView*)view;

- (void)addWrapPickerView:(WLAddWrapPickerView*)view didAddWrap:(WLWrap*)wrap;

@end

@interface WLAddWrapPickerView : WLEntryReusableView

@property (weak, nonatomic, readonly) UITextField *wrapNameTextField;

@property (weak, nonatomic) IBOutlet id <WLAddWrapPickerViewDelegate> delegate;

@end
