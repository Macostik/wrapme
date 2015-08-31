//
//  WLEmojiCell.m
//  moji
//
//  Created by Ravenpod on 5/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmojiCell.h"
#import "UIFont+CustomFonts.h"

@interface WLEmojiCell ()

@property (weak, nonatomic) IBOutlet UILabel *emojiLabel;

@end

@implementation WLEmojiCell

- (void)setup:(NSString*)item {
	self.emojiLabel.text = item;
}

@end
