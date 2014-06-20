//
//  WLRefreshControl.h
//  WrapLive
//
//  Created by Sergey Maximenko on 07.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, WLRefresherScrollDirection) {
	WLRefresherScrollDirectionVertical,
	WLRefresherScrollDirectionHorizontal
};

typedef NS_ENUM(NSUInteger, WLRefresherColorScheme) {
	WLRefresherColorSchemeWhite,
	WLRefresherColorSchemeOrange
};

@interface WLRefresher : UIControl

@property (nonatomic) WLRefresherColorScheme colorScheme;

@property (nonatomic) BOOL refreshing;

+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView refreshBlock:(void (^)(WLRefresher* refresher))refreshBlock;
+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView target:(id)target action:(SEL)action colorScheme:(WLRefresherColorScheme)colorScheme;
+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView target:(id)target action:(SEL)action;
+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView;
+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView direction:(WLRefresherScrollDirection)direction;


- (void)endRefreshing;

- (void)endRefreshingAfterDelay:(NSTimeInterval)delay;

@end
