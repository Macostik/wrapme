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

@interface WLRefresher : UIControl

+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView refreshBlock:(void (^)(WLRefresher* refresher))refreshBlock;
+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView;
+ (WLRefresher*)refresherWithScrollView:(UIScrollView*)scrollView direction:(WLRefresherScrollDirection)direction;

- (void)endRefreshing;

@end
