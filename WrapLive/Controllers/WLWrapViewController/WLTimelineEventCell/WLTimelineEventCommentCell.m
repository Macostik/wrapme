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
#import "WLCandyViewController.h"

static CGFloat WLTimelineEventCommentCellMinHeight = 30.0f;
static CGFloat WLTimelineEventCommentCellQuoteWidth = 30.0f;
static CGFloat WLTimelineEventCommentFooterHeight = 40.0f;
static CGFloat WLTimelineEventCommentCandyWidth = 100.0f;
static CGFloat WLTimelineEventCommentsMinWidth;
static CGFloat WLTimelineEventImageViewMaxHeightAndWidth;

@interface WLTimelineEventCommentCell () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet WLImageView *imageView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coverImageWidthContstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *coverImageHeightConstraint;

@end

@implementation WLTimelineEventCommentCell

+ (void)initialize {
    WLTimelineEventCommentsMinWidth = [UIWindow mainWindow].width - WLTimelineEventCommentCandyWidth -
                                        2*WLTimelineDefaultLeftRightOffset - WLTimelineEventCommentCellQuoteWidth;
    WLTimelineEventImageViewMaxHeightAndWidth = ([UIWindow mainWindow].width - 1.0 - 2*WLTimelineDefaultLeftRightOffset)/3.0f;
}

+ (CGFloat)heightWithComment:(WLComment *)comment {
    if (!comment.valid) {
        return WLTimelineEventCommentCellMinHeight;
    }
    CGFloat height = [comment.text heightWithFont:[UIFont lightFontOfSize:17] width:WLTimelineEventCommentsMinWidth cachingKey:"timelineCommentTextHeight"];
    return MAX(WLTimelineEventCommentCellMinHeight, height + 6);
}

+ (CGFloat)heightWithComments:(NSOrderedSet *)comments {
    CGFloat height = WLTimelineEventCommentFooterHeight;
    for (WLComment* comment in comments) {
        height += [self heightWithComment:comment];
    }
    return MAX(WLTimelineEventImageViewMaxHeightAndWidth, height);
}

- (void)setup:(NSOrderedSet*)comments {
    WLComment* comment = [comments firstObject];
    self.imageView.url = comment.picture.small;
    self.coverImageHeightConstraint.constant = self.coverImageWidthContstraint.constant = WLTimelineEventImageViewMaxHeightAndWidth;
    [self.imageView layoutIfNeeded];
    [self.collectionView reloadData];
}

- (void)select:(NSOrderedSet*)comments {
    [super select:[[comments lastObject] candy]];
}

- (IBAction)comment:(id)sender {
    [self select:self.entry];
    WLCandyViewController* controller = (id)[UINavigationController mainNavigationController].topViewController;
    if ([controller isKindOfClass:[WLCandyViewController class]]) {
        controller.showCommentInputKeyboard = YES;
    }
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"WLCommentButtonView" forIndexPath:indexPath];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    return CGSizeMake(collectionView.width, WLTimelineEventCommentFooterHeight);
}

@end
