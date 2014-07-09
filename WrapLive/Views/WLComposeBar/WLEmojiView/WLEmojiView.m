//
//  WLEmojiView.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/21/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEmojiView.h"
#import "WLEmojiCell.h"
#import "NSObject+NibAdditions.h"
#import "SegmentedControl.h"
#import "UIColor+CustomColors.h"
#import "NSObject+NibAdditions.h"
#import "NSArray+Additions.h"
#import "WLEmoji.h"

@interface WLEmojiView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SegmentedControlDelegate>

@property (strong, nonatomic) UIView * emojiView;
@property (strong, nonatomic) NSArray * emojis;
@property (strong, nonatomic) IBOutlet UICollectionView * collectionView;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@end

@implementation WLEmojiView

- (instancetype)initWithSelectionBlock:(WLStringBlock)selectionBlock
						   returnBlock:(WLBlock)returnBlock
			  andSegmentSelectionBlock:(WLIntegerBlock)segmentSelectionBlock {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 216)];
    if (self) {
		self.selectionBlock = selectionBlock;
		self.returnBlock = returnBlock;
		self.segmentSelectionBlock = segmentSelectionBlock;
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
	if (self.returnBlock) {
		self.returnBlock();
	}
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
//    return CGSizeMake(50, 50);
	return CGSizeMake(collectionView.frame.size.width/7, collectionView.frame.size.height/3);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selectionBlock) {
		NSString * selectedEmoji = [self.emojis objectAtIndex:indexPath.item];
        [WLEmoji saveAsRecent:selectedEmoji];
		self.selectionBlock(selectedEmoji);
	}
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
	if (self.segmentSelectionBlock) {
		self.segmentSelectionBlock(segment);
	}
    [self setScrollDirection];
	[self.collectionView setContentOffset:CGPointZero];
	[self.collectionView reloadData];
}

@end
