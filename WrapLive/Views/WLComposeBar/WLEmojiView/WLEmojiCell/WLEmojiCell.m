//
//  WLEmojiCell.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/21/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEmojiCell.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"

@interface WLEmojiCell ()

@property (weak, nonatomic) UILabel *emojiLabel;

@end

@implementation WLEmojiCell

- (UILabel *)emojiLabel {
	if (!_emojiLabel) {
		UILabel *emojiLabel = [[UILabel alloc] initWithFrame:self.bounds];
		emojiLabel.font = [UIFont fontWithName:WLFontOpenSansRegular size:34];
		emojiLabel.textAlignment = NSTextAlignmentCenter;
		[self addSubview:emojiLabel];
		[emojiLabel setFullFlexible];
		_emojiLabel = emojiLabel;
	}
	return _emojiLabel;
}

- (void)setupItemData:(NSString*)item {
	self.emojiLabel.text = item;
}

@end
