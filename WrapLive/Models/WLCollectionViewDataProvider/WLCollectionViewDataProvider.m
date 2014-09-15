//
//  WLCollectionViewDataProvider.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionViewDataProvider.h"
#import "AsynchronousOperation.h"
#import "WLSupportFunctions.h"
#import "UIView+Shorthand.h"
#import "UIScrollView+Additions.h"

@interface WLCollectionViewDataProvider ()

@end

@implementation WLCollectionViewDataProvider

+ (instancetype)dataProvider:(UICollectionView*)collectionView {
    return [self dataProvider:collectionView sections:nil];
}

+ (instancetype)dataProvider:(UICollectionView*)collectionView sections:(NSArray*)sections {
    WLCollectionViewDataProvider* dataProvider = [[WLCollectionViewDataProvider alloc] init];
    dataProvider.sections = [NSMutableArray arrayWithArray:sections];
    dataProvider.collectionView = collectionView;
    [sections makeObjectsPerformSelector:@selector(setCollectionView:) withObject:collectionView];
    [dataProvider connect];
    return dataProvider;
}

+ (instancetype)dataProvider:(UICollectionView*)collectionView section:(WLCollectionViewSection*)section {
    return [self dataProvider:collectionView sections:@[section]];
}

- (void)dealloc {
    UICollectionView* cv = self.collectionView;
    if (cv.delegate == self) cv.delegate = nil;
    if (cv.dataSource == self) cv.dataSource = nil;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.sections makeObjectsPerformSelector:@selector(setDataProvider:) withObject:self];
}

- (void)setSections:(NSMutableArray *)sections {
    _sections = sections;
    [sections makeObjectsPerformSelector:@selector(setDataProvider:) withObject:self];
    [self reload];
}

- (void)reload {
    [self.collectionView reloadData];
}

- (void)reload:(WLCollectionViewSection*)section {
    [self reload];
}

- (void)connect {
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
}

- (void)setRefreshable {
    [self setRefreshableWithStyle:WLRefresherStyleWhite];
}

- (void)setRefreshableWithStyle:(WLRefresherStyle)style contentMode:(UIViewContentMode)contentMode {
    [self setRefreshableWithStyle:style contentMode:contentMode];
}

- (void)setRefreshableWithContentMode:(UIViewContentMode)contentMode {
    [self setRefreshableWithStyle:WLRefresherStyleWhite contentMode:contentMode];
}

- (void)setRefreshableWithStyle:(WLRefresherStyle)style {
    [WLRefresher refresher:self.collectionView target:self action:@selector(refresh:) style:style];
}

- (void)refresh:(WLRefresher*)sender {
    NSOperationQueue *refreshingQueue = [[NSOperationQueue alloc] init];
    for (WLCollectionViewSection* section in _sections) {
        [refreshingQueue addAsynchronousOperationWithBlock:^(AsynchronousOperation *operation) {
            [section refresh:^(NSOrderedSet *orderedSet) {
                [operation finish:^{
                    [sender setRefreshing:NO animated:YES];
                }];
            } failure:^(NSError *error) {
                [operation finish:^{
                    [sender setRefreshing:NO animated:YES];
                    [error showIgnoringNetworkError];
                }];
            }];
        }];
    }
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [self.sections count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    WLCollectionViewSection* _section = _sections[section];
    return [_section numberOfEntries];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLCollectionViewSection* _section = _sections[indexPath.section];
    return [_section cell:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    WLCollectionViewSection* _section = _sections[indexPath.section];
    if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
        return [_section header:indexPath];
    } else {
        return [_section footer:indexPath];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    WLCollectionViewSection* _section = _sections[section];
    return [_section headerSize:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    WLCollectionViewSection* _section = _sections[section];
    return [_section footerSize:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLCollectionViewSection* _section = _sections[indexPath.section];
    return [_section size:indexPath];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    WLCollectionViewSection* _section = _sections[section];
    return [_section minimumLineSpacing:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    WLCollectionViewSection* _section = _sections[section];
    return [_section minimumInteritemSpacing:section];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    WLCollectionViewSection* _section = _sections[section];
    return [_section sectionInsets:section];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WLCollectionViewSection* section = _sections[indexPath.section];
    [section select:indexPath];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    for (WLCollectionViewSection* section in _sections) {
        [section scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	for (WLCollectionViewSection* section in _sections) {
        [section scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    for (WLCollectionViewSection* section in _sections) {
        [section scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    for (WLCollectionViewSection* section in _sections) {
        [section scrollViewDidScroll:scrollView];
    }
    if (self.animationViews.nonempty && scrollView.tracking) {
        if (scrollView.contentSize.height > scrollView.height || self.direction == DirectionUp) {
            self.direction = [scrollView.panGestureRecognizer translationInView:scrollView].y > 0 ? DirectionDown : DirectionUp;
        }
    }
}

- (void)setDirection:(Direction)direction {
    if (_direction != direction) {
        _direction = direction;
        UICollectionView* cv = self.collectionView;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationDuration:0.3];
        CGAffineTransform (^transform) (UIView* view) = nil;
        if (direction == DirectionDown) {
            transform = ^CGAffineTransform (UIView* view) {
                return CGAffineTransformIdentity;
            };
        } else if (direction == DirectionUp) {
            transform = ^CGAffineTransform (UIView* subview) {
                if(IsInBounds(0, cv.width/3, subview.center.x)) {
                    return CGAffineTransformMakeTranslation(-CGRectGetMaxX(subview.frame), 0);
                } else if(IsInBounds(2*cv.width/3, cv.width, subview.center.x)) {
                    return CGAffineTransformMakeTranslation(subview.x, 0);
                } else if(IsInBounds(0, cv.height/2, subview.center.y)) {
                    return CGAffineTransformMakeTranslation(0, -CGRectGetMaxY(subview.frame));
                } else {
                    return CGAffineTransformMakeTranslation(0, subview.y);
                }
            };
        }
        for (UIView* subview in self.animationViews) {
            if (subview == cv) continue;
            subview.transform = transform(subview);
        }
        [UIView commitAnimations];
    }
}

@end

@implementation WLCollectionViewSection (WLCollectionViewDataProvider)

- (void)reload {
    [self.dataProvider reload:self];
}

@end
