//
//  WLCreateWrapViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEditViewController.h"

@class WLWrap;
@class WLPicture;
@class WLCreateWrapViewController;

@protocol WLCreateWrapViewControllerDelegate <NSObject>

- (void)createWrapViewController:(WLCreateWrapViewController*)controller didCreateWrap:(WLWrap*)wrap;

- (void)createWrapViewControllerDidCancel:(WLCreateWrapViewController*)controller;

@end

@interface WLCreateWrapViewController : WLEditViewController

@property (strong, nonatomic) WLWrap* wrap;

@property (strong, nonatomic) NSArray *pictures;

@property (nonatomic, weak) id <WLCreateWrapViewControllerDelegate> delegate;

@end
