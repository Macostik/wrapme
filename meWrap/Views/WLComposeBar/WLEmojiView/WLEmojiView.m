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

@property (strong, nonatomic) UIView * emojiView;
@property (strong, nonatomic) NSArray * emojis;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;
@property (weak, nonatomic) UITextView* textView;
@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;
@property (strong, nonatomic) IBOutlet GridMetrics *metrics;

@end

@implementation WLEmojiView

+ (instancetype)emojiViewWithTextView:(UITextView *)textView {
    WLEmojiView *view = [self loadFromNib];
    view.textView = textView;
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if ([[WLEmoji recentEmoji] nonempty]) {
        self.emojis = [WLEmoji recentEmoji];
    } else {
        self.segmentedControl.selectedSegment = 1;
        self.emojis = [WLEmoji emojiByType:WLEmojiTypeSmiles];
    }
    __weak typeof(self)weakSelf = self;
    
    StreamView *streamView = self.dataSource.streamView;
    [self.metrics setRatioAt:^CGFloat(StreamPosition * __nonnull index, GridMetrics * __nonnull metrics) {
        return (streamView.frame.size.width/7) / (streamView.frame.size.height/3);
    }];
    
    [self.metrics setSelection:^(StreamItem * __nonnull item, NSString * __nonnull emoji) {
        [WLEmoji saveAsRecent:emoji];
        [weakSelf.textView insertText:emoji];
    }];
}

- (IBAction)returnClicked:(UIButton *)sender {
    [self.textView deleteBackward];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString * selectedEmoji = [self.emojis objectAtIndex:indexPath.item];
    [WLEmoji saveAsRecent:selectedEmoji];
    [self.textView insertText:selectedEmoji];
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
