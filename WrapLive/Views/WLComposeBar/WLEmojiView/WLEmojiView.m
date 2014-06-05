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
#import "NSPropertyListSerialization+Shorthand.h"

@interface WLEmojiView () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, SegmentedControlDelegate>

@property (strong, nonatomic)  UIView * emojiView;
@property (strong, nonatomic) NSArray * emojis;
@property (strong, nonatomic) IBOutlet UICollectionView * collectionView;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentedControl;

@end

@implementation WLEmojiView

- (instancetype)initWithSelectionBlock:(WLEmojiSelectionBlock)selectionBlock andReturnBlock:(WLEmojiReturnBlock)returnBlock {
    self = [super initWithFrame:CGRectMake(0, 0, 320, 216)];
    if (self) {
		self.selectionBlock = selectionBlock;
		self.returnBlock = returnBlock;
		self.emojiView = [UIView loadFromNibNamed:@"WLEmojiView" ownedBy:self];
		self.emojiView.frame = self.bounds;
		[self addSubview:self.emojiView];
		[self.collectionView registerClass:[WLEmojiCell class] forCellWithReuseIdentifier:@"WLEmojiCell"];
		self.emojis = [NSArray resourcePropertyListNamed:@"smiles"];
    }
    return self;
}

- (IBAction)returnClicked:(UIButton *)sender {
	if (self.returnBlock) {
		self.returnBlock();
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
	return CGSizeMake(collectionView.frame.size.width/8, collectionView.frame.size.height/4);
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selectionBlock) {
		NSString * selectedEmoji = [self.emojis objectAtIndex:indexPath.item];
		self.selectionBlock(selectedEmoji);
	}
}

#pragma mark - SegmentedControlDelegate

- (void)segmentedControl:(SegmentedControl*)control didSelectSegment:(NSInteger)segment {
	if (segment == 0) {
		self.emojis = [NSArray resourcePropertyListNamed:@"smiles"];
	} else if (segment == 1) {
		self.emojis = [NSArray resourcePropertyListNamed:@"flowers"];
	} else if (segment == 2){
		self.emojis = [NSArray resourcePropertyListNamed:@"rings"];
	} else if (segment == 3){
		self.emojis = [NSArray resourcePropertyListNamed:@"cars"];
	} else {
		self.emojis = [NSArray resourcePropertyListNamed:@"numbers"];
	}
	[self.collectionView setContentOffset:CGPointZero];
	[self.collectionView reloadData];
}

@end
