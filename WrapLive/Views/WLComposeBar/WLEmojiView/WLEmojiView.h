//
//  WLEmojiView.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/21/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WLEmojiSelectionBlock)(NSString* emoji);

typedef void (^WLEmojiReturnBlock)();

@interface WLEmojiView : UIView

@property (strong, nonatomic) WLEmojiSelectionBlock selectionBlock;
@property (strong, nonatomic) WLEmojiReturnBlock returnBlock;

- (instancetype)initWithSelectionBlock:(WLEmojiSelectionBlock)selectionBlock andReturnBlock:(WLEmojiReturnBlock)returnBlock;

@end
