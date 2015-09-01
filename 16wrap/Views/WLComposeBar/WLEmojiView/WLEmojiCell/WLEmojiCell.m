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

@property (weak, nonatomic) UILabel *emojiLabel;

@end

@implementation WLEmojiCell

- (UILabel *)emojiLabel {
	if (!_emojiLabel) {
		UILabel *emojiLabel = [[UILabel alloc] initWithFrame:self.bounds];
		emojiLabel.font = [UIFont fontWithName:WLDefaultSystemLightFont size:34];
		emojiLabel.textAlignment = NSTextAlignmentCenter;
		[self addSubview:emojiLabel];
		[emojiLabel setFullFlexible];
		_emojiLabel = emojiLabel;
	}
	return _emojiLabel;
}

- (void)setup:(NSString*)item {
	self.emojiLabel.text = item;
}

@end
