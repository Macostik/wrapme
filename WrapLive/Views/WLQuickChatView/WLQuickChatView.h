//
//  WLQuickChatView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLWrap;
@class WLQuickChatView;

@protocol WLQuickChatViewDelegate <NSObject>

- (void)quickChatView:(WLQuickChatView*)view didOpenChat:(WLWrap*)wrap;

@end

@interface WLQuickChatView : UIView

@property (nonatomic, weak) IBOutlet id <WLQuickChatViewDelegate> delegate;

@property (strong, nonatomic) WLWrap* wrap;

@property (nonatomic) BOOL editing;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

- (void)onEndScrolling;

- (void)onScroll;

@end
