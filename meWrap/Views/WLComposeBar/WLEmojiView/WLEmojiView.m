//
//  WLEmojiView.m
//  meWrap
//
//  Created by Ravenpod on 5/21/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEmojiView.h"
#import "WLEmojiCell.h"
#import "NSObject+NibAdditions.h"
#import "SegmentedControl.h"
#import "UIColor+CustomColors.h"
#import "NSObject+NibAdditions.h"
#import "WLCollections.h"
#import "WLEmoji.h"
#import "StreamDataSource.h"

@interface WLEmojiView () <SegmentedControlDelegate>

@property (weak, nonatomic) IBOutlet StreamView *streamView;
@property (strong, nonatomic) NSArray * emojis;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;
@property (weak, nonatomic) UITextView* textView;
@property (strong, nonatomic) StreamDataSource *dataSource;

@end

@implementation WLEmojiView

+ (instancetype)emojiViewWithTextView:(UITextView *)textView {
    WLEmojiView *view = [self loadFromNib];
    view.textView = textView;
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    __weak typeof(self)weakSelf = self;
    StreamView *streamView = self.streamView;
    
    self.streamView.layout = [[GridLayout alloc] initWithHorizontal:YES];
    self.dataSource = [StreamDataSource dataSourceWithStreamView:self.streamView];
    [self.dataSource addMetrics:[[GridMetrics alloc] initWithIdentifier:@"WLEmojiCell" initializer:^(StreamMetrics *metrics) {
        [(GridMetrics*)metrics setRatioAt:^CGFloat(StreamPosition * __nonnull index, GridMetrics * __nonnull metrics) {
            return (streamView.frame.size.height/3) / (streamView.frame.size.width/7);
        }];
        
        [(GridMetrics*)metrics setSelection:^(StreamItem * __nonnull item, NSString * __nonnull emoji) {
            [WLEmoji saveAsRecent:emoji];
            [weakSelf.textView insertText:emoji];
        }];
    }]];
    self.dataSource.numberOfGridColumns = 3;
    self.dataSource.sizeForGridColumns = 0.3333f;
    
    if ([[WLEmoji recentEmoji] nonempty]) {
        self.emojis = [WLEmoji recentEmoji];
    } else {
        self.segmentedControl.selectedSegment = 1;
        self.emojis = [WLEmoji emojiByType:WLEmojiTypeSmiles];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [UIView performWithoutAnimation:^{
        [self.dataSource reload];
    }];
}

- (IBAction)returnClicked:(UIButton *)sender {
    [self.textView deleteBackward];
}

- (void)setEmojis:(NSArray *)emojis {
    _emojis = emojis;
    self.dataSource.items = emojis;
}

#pragma mark - SegmentedControlDelegate

- (void)segmentedControl:(SegmentedControl*)control didSelectSegment:(NSInteger)segment {
    [self.dataSource.streamView setContentOffset:CGPointZero];
	if (segment == 0) {
		self.emojis = [WLEmoji recentEmoji];
	} else if (segment == 1) {
		self.emojis = [WLEmoji emojiByType:WLEmojiTypeSmiles];
	} else if (segment == 2){
		self.emojis = [WLEmoji emojiByType:WLEmojiTypeFlowers];
	} else if (segment == 3){
		self.emojis = [WLEmoji emojiByType:WLEmojiTypeRings];
	} else if (segment == 4){
		self.emojis = [WLEmoji emojiByType:WLEmojiTypeCars];
    } else {
		self.emojis = [WLEmoji emojiByType:WLEmojiTypeNumbers];
	}
}

@end
