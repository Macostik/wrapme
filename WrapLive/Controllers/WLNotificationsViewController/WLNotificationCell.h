//
//  WLNotificationCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"

const static CGFloat WLNotificationCommentHorizontalSpacing = 134.0f;
const static CGFloat WLNotificationCommentVerticalSpacing = 77.0f;
const static CGFloat WLMinHeightCell = 41.0f;

@class WLNotificationCell, WLComposeBar, WLTextView;

@protocol WLNotificationCellDelegate <NSObject>

- (void)notificationCell:(WLNotificationCell *)cell didRetryMessageByComposeBar:(WLComposeBar *)composeBar;
- (void)notificationCell:(WLNotificationCell *)cell didChangeHeightComposeBar:(WLComposeBar *)composeBar;
- (void)notificationCell:(WLNotificationCell *)cell beginEditingComposaBar:(WLComposeBar* )composeBar;
- (void)notificationCell:(WLNotificationCell *)cell calculateHeightTextView:(CGFloat)height;
- (void)notificationCell:(WLNotificationCell *)cell createEntry:(id)entry;
- (id)notificationCell:(WLNotificationCell *)cell createdEntry:(id)entry;


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
