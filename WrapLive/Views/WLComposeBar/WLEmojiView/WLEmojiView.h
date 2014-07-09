//
//  WLEmojiView.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/21/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLBlocks.h"

@interface WLEmojiView : UIView

@property (strong, nonatomic) WLStringBlock selectionBlock;
@property (strong, nonatomic) WLBlock returnBlock;
@property (strong, nonatomic) WLIntegerBlock segmentSelectionBlock;

- (instancetype)initWithSelectionBlock:(WLStringBlock)selectionBlock
						   returnBlock:(WLBlock)returnBlock
			  andSegmentSelectionBlock:(WLIntegerBlock)segmentSelectionBlock;

@end
