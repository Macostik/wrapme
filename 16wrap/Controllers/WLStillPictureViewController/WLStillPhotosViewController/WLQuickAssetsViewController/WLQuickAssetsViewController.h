//
//  WLQuickAssetsViewController.h
//  moji
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PHAsset, WLQuickAssetsViewController;

@protocol WLQuickAssetsViewControllerDelegate <NSObject>

@optional

- (BOOL)quickAssetsViewControllerShouldPreselectFirstAsset:(WLQuickAssetsViewController*)controller;

- (BOOL)quickAssetsViewController:(WLQuickAssetsViewController*)controller shouldSelectAsset:(PHAsset*)asset;

- (void)quickAssetsViewController:(WLQuickAssetsViewController*)controller didSelectAsset:(PHAsset*)asset;

- (void)quickAssetsViewController:(WLQuickAssetsViewController*)controller didDeselectAsset:(PHAsset*)asset;

@end

@interface WLQuickAssetsViewController : UIViewController

@property (nonatomic) BOOL allowsMultipleSelection;

@property (weak, nonatomic) id <WLQuickAssetsViewControllerDelegate> delegate;

@end
