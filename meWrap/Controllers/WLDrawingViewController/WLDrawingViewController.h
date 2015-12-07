//
//  WLDrawingViewController.h
//  Wrap
//
//  Created by Sergey Maximenko on 8/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLDrawingViewController;

@protocol WLDrawingViewControllerDelegate <NSObject>

@optional
- (void)drawingViewController:(WLDrawingViewController*)controller didFinishWithImage:(UIImage*)image;

- (void)drawingViewControllerDidCancel:(WLDrawingViewController*)controller;

@end

@interface WLDrawingViewController : WLBaseViewController

@property (nonatomic, weak) IBOutlet id <WLDrawingViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;

@property (strong, nonatomic) UIImage *image;

+ (instancetype)draw:(UIImage*)image finish:(ImageBlock)finish;

- (void)setImage:(UIImage*)image done:(ImageBlock)done cancel:(Block)cancel;

@end
