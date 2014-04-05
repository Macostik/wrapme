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

@protocol WLProgressBarDelegate <NSObject>

- (void)progressBar:(WLProgressBar*)progressBar didChangeProgress:(float)progress;

@end

@interface WLProgressBar : UIView

@property (nonatomic, weak) IBOutlet id <WLProgressBarDelegate> delegate;

@property (nonatomic, weak) AFURLConnectionOperation *operation;

@property (nonatomic) CGFloat progress;

- (void)setProgress:(float)progress animated:(BOOL)animated;

@end
