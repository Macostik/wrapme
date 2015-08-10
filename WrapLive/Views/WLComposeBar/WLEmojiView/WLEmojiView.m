//
//  WLEmojiView.m
//  moji
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

@interface WLEmojiView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SegmentedControlDelegate>

@property (strong, nonatomic) UIView * emojiView;
@property (strong, nonatomic) NSArray * emojis;
@property (strong, nonatomic) IBOutlet UICollectionView * collectionView;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (weak, nonatomic) UITextView* textView;

@end

@implementation WLEmojiView

- (instancetype)initWithTextView:(UITextView *)textView {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 216)];
    if (self) {
		self.textView = textView;
		self.emojiView = [UIView loadFromNibNamed:@"WLEmojiView" ownedBy:self];
		self.emojiView.frame = self.bounds;
		[self addSubview:self.emojiView];
		[self.collectionView registerClass:[WLEmojiCell class] forCellWithReuseIdentifier:@"WLEmojiCell"];
        if ([[WLEmoji recentEmoji] nonempty]) {
            self.emojis = [WLEmoji recentEmoji];
        } else {
            self.emojis = [WLEmoji emojiByType:WLEmojiTypeSmiles];
            self.segmentedControl.selectedSegment = 1;
        }
        [self setScrollDirection];
    }
    return self;
}

- (IBAction)returnClicked:(UIButton *)sender {
    [self.textView deleteBackward];
}

- (void)setScrollDirection {
    if (self.segmentedControl.selectedSegment == 0) {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    } else {
        self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.emojis.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	WLEmojiCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WLEmojiCell reuseIdentifier] forIndexPath:indexPath];
	cell.item = [self.emojis objectAtIndex:indexPath.item];
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	return CGSizeMake(collectionView.frame.size.width/7, collectionView.frame.size.height/3);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString * selectedEmoji = [self.emojis objectAtIndex:indexPath.item];
    [WLEmoji saveAsRecent:selectedEmoji];
    [self.textView insertText:selectedEmoji];
}

#pragma mark - SegmentedControlDelegate

- (void)segmentedControl:(SegmentedControl*)control didSelectSegment:(NSInteger)segment {
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
    [self setScrollDirection];
	[self.collectionView setContentOffset:CGPointZero];
	[self.collectionView reloadData];
}

@end
