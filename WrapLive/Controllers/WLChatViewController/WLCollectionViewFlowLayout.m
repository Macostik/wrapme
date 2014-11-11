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

- (CGAffineTransform)adjustmentTransform:(CGFloat)inset {
    return inset > 0 ? CGAffineTransformTranslate(self.collectionView.transform, 0, -inset) : self.collectionView.transform;
}

- (UICollectionViewLayoutAttributes *)adjustAttributes:(UICollectionViewLayoutAttributes *)attributes transform:(CGAffineTransform)transform {
	if (!CGAffineTransformEqualToTransform(attributes.transform, transform)) {
		attributes.transform = transform;
	}
	return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGAffineTransform transform = [self adjustmentTransform:self.inset];
	return [self adjustAttributes:[super layoutAttributesForItemAtIndexPath:indexPath] transform:transform];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    CGAffineTransform transform = [self adjustmentTransform:self.inset];
	return [self adjustAttributes:[super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath] transform:transform];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSArray* attributes = [super layoutAttributesForElementsInRect:rect];
    CGAffineTransform transform = [self adjustmentTransform:self.inset];
	for (UICollectionViewLayoutAttributes* attr in attributes) {
		[self adjustAttributes:attr transform:transform];
	}
	return attributes;
}

@end
