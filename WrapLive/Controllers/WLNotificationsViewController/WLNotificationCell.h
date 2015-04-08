//
//  WLNotificationCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

const static CGFloat WLNotificationCommentHorizontalSpacing = 137.0f;
const static CGFloat WLNotificationCommentVerticalSpacing = 78.0f;

@class WLNotificationCell, WLComposeBar;

@protocol WLNotificationCellDelegate <NSObject>

- (void)notificationCell:(WLNotificationCell *)cell didRetryMessageThroughComposeBar:(WLComposeBar *)composeBar;

@end

@interface WLNotificationCell : WLEntryCell

@property (assign, nonatomic) IBOutlet id <WLNotificationCellDelegate> delegate;

+ (CGFloat)heightCell:(id)entry;
- (void)sendMessageWithText:(NSString *)text;

@end

@interface WLMessageNotificationCell : WLNotificationCell

@end

@interface WLCommentNotificationCell : WLNotificationCell

@end

@interface WLCandyNotificationCell : WLNotificationCell

@end
