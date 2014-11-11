//
//  WLCollectionViewFlowLayout.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/11/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCollectionViewFlowLayout.h"
#import "UIView+Shorthand.h"
#import "UIScrollView+Additions.h"

@interface WLCollectionViewFlowLayout ()

@property (strong, nonatomic) UICollectionViewFlowLayoutInvalidationContext* invalidationContext;

@end

@implementation WLCollectionViewFlowLayout

- (void)awakeFromNib {
    [super awakeFromNib];
    UICollectionViewFlowLayoutInvalidationContext* context = [[UICollectionViewFlowLayoutInvalidationContext alloc] init];
    context.invalidateFlowLayoutDelegateMetrics = YES;
    context.invalidateFlowLayoutAttributes = YES;
    self.invalidationContext = context;
}

- (void)invalidate {
    [self invalidateLayoutWithContext:self.invalidationContext];
}

- (CGFloat)inset {
    UICollectionView* cv = self.collectionView;
    CGFloat height = (cv.height - cv.verticalContentInsets);
    return MAX(0, height - [self collectionViewContentSize].height);
}

- (UICollectionViewLayoutAttributes *)adjustAttributes:(UICollectionViewLayoutAttributes *)attributes inset:(CGFloat)inset {
    CGAffineTransform transform = self.collectionView.transform;
    if (inset > 0 && attributes.indexPath.section != 0) {
        transform = CGAffineTransformTranslate(transform, 0, -inset);
    }
	if (!CGAffineTransformEqualToTransform(attributes.transform, transform)) {
		attributes.transform = transform;
	}
	return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self adjustAttributes:[super layoutAttributesForItemAtIndexPath:indexPath] inset:self.inset];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	return [self adjustAttributes:[super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath] inset:self.inset];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSArray* attributes = [super layoutAttributesForElementsInRect:rect];
    CGFloat inset = self.inset;
	for (UICollectionViewLayoutAttributes* attr in attributes) {
		[self adjustAttributes:attr inset:inset];
	}
	return attributes;
}

@end
