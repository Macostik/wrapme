//
//  WLChatLayout.h
//  wrapLive
//
//  Created by Sergey Maximenko on 7/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLCollectionViewLayout.h"

@interface WLChatLayout : WLCollectionViewLayout

@property (strong, nonatomic) NSIndexPath *unreadMessagesViewIndexPath;

@property (nonatomic) BOOL scrollToUnreadMessages;

@end
