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
- (void)drawingViewController:(WLDrawingViewController* __nonnull)controller didFinishWithImage:(UIImage* __nonnull)image;

- (void)drawingViewControllerDidCancel:(WLDrawingViewController* __nonnull)controller;

@end

@interface WLDrawingViewController : WLBaseViewController

@property (nonatomic, weak) IBOutlet id <WLDrawingViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;

@property (strong, nonatomic) UIImage *__nullable image;

+ (instancetype __nullable)draw:(UIImage*__nonnull)image finish:(void (^__nonnull)(UIImage*__nonnull image))finish;

- (void)setImage:(UIImage*__nonnull)image done:(void (^__nonnull)(UIImage*__nonnull image))done cancel:(Block __nonnull)cancel;

@end
