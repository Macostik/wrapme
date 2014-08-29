//
//  WLLoadingView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLLoadingView : UICollectionReusableView

@property (nonatomic) BOOL animating;

@property (nonatomic) BOOL error;

+ (instancetype)instance;

+ (instancetype)splash;

- (instancetype)showInView:(UIView*)view;

- (void)hide;

@end
