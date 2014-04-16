//
//  PGProgressBar.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 6/21/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AFURLConnectionOperation;
@class WLProgressBar;
@class WLUploadingItem;

@protocol WLProgressBarDelegate <NSObject>

- (void)progressBar:(WLProgressBar*)progressBar didChangeProgress:(float)progress;

@end

@interface WLProgressBar : UIView
{
@protected
	float _progress;
}

@property (nonatomic, weak) IBOutlet id <WLProgressBarDelegate> delegate;

@property (nonatomic, weak) AFURLConnectionOperation *operation;

@property (nonatomic, weak) WLUploadingItem *uploadingItem;

@property (nonatomic) float progress;

@property (strong, nonatomic, readonly) UIView *backgroundView;
@property (strong, nonatomic, readonly) UIView *progressView;

- (void)setProgress:(float)progress animated:(BOOL)animated;

- (void)updateProgressViewAnimated:(BOOL)animated difference:(float)difference;

- (void)setup;

- (UIView*)initializeBackgroundView;

- (UIView*)initializeProgressViewWithBackgroundView:(UIView*)backgroundView;

@end
