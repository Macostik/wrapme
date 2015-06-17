//
//  WLChatViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.04.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLChatViewController;

@protocol WLChatViewControllerDelegate <NSObject>

- (void)chatViewController:(WLChatViewController *)controller resetUnreageMessageCounter:(BOOL)reset;

@end

@interface WLChatViewController : WLBaseViewController

@property (nonatomic, weak) WLWrap* wrap;

@property (weak, nonatomic) id <WLChatViewControllerDelegate> delegate;

@end
