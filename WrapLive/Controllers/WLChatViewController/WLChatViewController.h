//
//  WLChatViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapEmbeddedViewController.h"

@class WLChatViewController;

@protocol WLChatViewControllerDelegate <WLWrapEmbeddedViewControllerDelegate>

@optional
- (void)chatViewController:(WLChatViewController*)controller didChangeUnreadMessagesCount:(NSUInteger)unreadMessagesCount;

@end

@interface WLChatViewController : WLWrapEmbeddedViewController

@property (nonatomic, weak) id <WLChatViewControllerDelegate> delegate;

@end
