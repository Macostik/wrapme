//
//  WLNotificationCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

@class WLNotificationCell, WLComposeBar;

@protocol WLNotificationCellDelegate <NSObject>

- (void)notificationCell:(WLNotificationCell *)cell didRetryMessageThroughComposeBar:(WLComposeBar *)composeBar;

@end

@interface WLNotificationCell : WLEntryCell

@property (assign, nonatomic) IBOutlet id <WLNotificationCellDelegate> delegate;

@end

@interface WLMessageNotificationCell : WLNotificationCell

@end

@interface WLCandyNotificationCell : WLNotificationCell

@end
