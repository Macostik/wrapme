//
//  WLQuickChatView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLWrap;

@interface WLQuickChatView : UIView

+ (instancetype)quickChatView:(UITableView*)tableView;

@property (strong, nonatomic) WLWrap* wrap;

- (void)onEndScrolling;

- (void)onScroll;

@end

@interface UITableView (WLQuickChatView)

- (void)reloadDataAndFixBottomInset:(WLQuickChatView*)quickChatView;

@end
