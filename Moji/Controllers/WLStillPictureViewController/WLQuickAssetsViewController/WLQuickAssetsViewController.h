//
//  WLQuickAssetsViewController.h
//  moji
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ALAsset, WLQuickAssetsViewController;

@protocol WLQuickAssetsViewControllerDelegate <NSObject>

@optional

- (BOOL)quickAssetsViewControllerShouldPreselectFirstAsset:(WLQuickAssetsViewController*)controller;

- (BOOL)quickAssetsViewController:(WLQuickAssetsViewController*)controller shouldSelectAsset:(ALAsset*)asset;

- (void)quickAssetsViewController:(WLQuickAssetsViewController*)controller didSelectAsset:(ALAsset*)asset;

- (void)quickAssetsViewController:(WLQuickAssetsViewController*)controller didDeselectAsset:(ALAsset*)asset;

@end

@interface WLQuickAssetsViewController : UIViewController

@property (weak, nonatomic) id <WLQuickAssetsViewControllerDelegate> delegate;

@end
