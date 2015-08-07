//
//  WLDrawingView.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLDrawingView;

@protocol WLDrawingViewDelegate <NSObject>

@optional
- (void)drawingView:(WLDrawingView*)view didFinishWithImage:(UIImage*)image;

- (void)drawingViewDidCancel:(WLDrawingView*)view;

@end

@interface WLDrawingView : UIView

@property (nonatomic, weak) IBOutlet id <WLDrawingViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomViewHeightConstraint;

- (void)showInView:(UIView*)view;

- (void)setImage:(UIImage*)image;

- (void)setImage:(UIImage*)image done:(WLImageBlock)done cancel:(WLBlock)cancel;

@end
