//
//  WLTimelineEventCommentCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTimelineEventCommentCell.h"
#import "WLImageView.h"
#import "WLComment.h"
#import "NSString+Additions.h"
#import "WLEntryManager.h"
#import "WLCommentCell.h"
#import "UIView+Shorthand.h"
#import "UIFont+CustomFonts.h"
#import "WLNavigation.h"

static CGFloat WLTimelineEventCommentCellMinHeight = 30.0f;
static CGFloat WLTimelineEventCommentMinHeight = 100.0f;
static CGFloat WLTimelineEventCommentMinBottomConstraint = 40.0f;
static CGFloat WLTimelineEventCommentMaxBottomConstraint = 70.0f;
static CGFloat WLTimelineEventCommentCandyWidth = 100.0f;
static CGFloat WLTimelineEventCommentsMinWidth;

@interface WLTimelineEventCommentCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

@end

@implementation WLTimelineEventCommentCell

+ (void)initialize {
    WLTimelineEventCommentsMinWidth = [UIWindow mainWindow].width - WLTimelineEventCommentCandyWidth;
}

+ (CGFloat)heightWithComment:(WLComment *)comment {
    if (!comment.valid) {
        return WLTimelineEventCommentCellMinHeight;
    }
    CGFloat height = [comment.text heightWithFont:[UIFont lightFontOfSize:15] width:WLTimelineEventCommentsMinWidth cachingKey:"timelineCommentTextHeight"];
    return MAX(WLTimelineEventCommentCellMinHeight, height + 6);
}

+ (CGFloat)heightWithComments:(NSOrderedSet *)comments {
    CGFloat height = WLTimelineEventCommentMinBottomConstraint;
    for (WLComment* comment in comments) {
        height += [self heightWithComment:comment];
    }
    return MAX(WLTimelineEventCommentMinHeight, height);
}

- (void)setup:(NSOrderedSet*)comments {
    WLComment* comment = [comments firstObject];
    self.imageView.url = comment.picture.small;
    [self.collectionView reloadData];
    CGFloat bottomConstraint = 0;
    if (self.height > WLTimelineEventCommentMinHeight) {
        bottomConstraint = WLTimelineEventCommentMinBottomConstraint;
    } else {
        bottomConstraint = WLTimelineEventCommentMaxBottomConstraint;
    }
    if (self.bottomConstraint.constant != bottomConstraint) {
        self.bottomConstraint.constant = bottomConstraint;
        [self.collectionView layoutIfNeeded];
    }
}

- (void)select:(id)entry {
    NSOrderedSet* comments = self.entry;
    [super select:[comments lastObject]];
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSOrderedSet* comments = self.entry;
    return comments.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSOrderedSet* comments = self.entry;
    WLComment* comment = [comments tryObjectAtIndex:indexPath.item];
    WLCommentCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLCommentCellIdentifier forIndexPath:indexPath];
    cell.entry = comment.valid ? comment : nil;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSOrderedSet* comments = self.entry;
    WLComment* comment = [comments tryObjectAtIndex:indexPath.item];
    return CGSizeMake(collectionView.width, [WLTimelineEventCommentCell heightWithComment:comment]);
}

@end
