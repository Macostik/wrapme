//
//  WLRefreshControl.h
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WLRefresherStyle) {
    WLRefresherStyleWhite_Clear,
	WLRefresherStyleWhite,
	WLRefresherStyleOrange
};

@class AFURLConnectionOperation;

@interface WLRefresher : UIControl

@property (nonatomic) WLRefresherStyle style;

@property (nonatomic) BOOL refreshing;

@property (nonatomic) CGFloat inset;

+ (WLRefresher*)refresher:(UIScrollView*)scrollView target:(id)target action:(SEL)action style:(WLRefresherStyle)style;

+ (WLRefresher*)refresher:(UIScrollView*)scrollView target:(id)target action:(SEL)action;

+ (WLRefresher*)refresher:(UIScrollView*)scrollView;

- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated;

@end
