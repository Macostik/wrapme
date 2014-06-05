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

@property (strong, nonatomic) WLWrap* wrap;

@property (nonatomic) BOOL editing;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;

- (void)onEndScrolling;

- (void)onScroll;

@end
