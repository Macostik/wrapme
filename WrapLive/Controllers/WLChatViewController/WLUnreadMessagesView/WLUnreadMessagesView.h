//
//  WLUnreadMessagesView.h
//  wrapLive
//
//  Created by Sergey Maximenko on 4/29/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLChat;

@interface WLUnreadMessagesView : UICollectionReusableView

- (void)updateWithChat:(WLChat*)chat;

@end
