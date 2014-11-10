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

@implementation WLCollectionViewFlowLayout

- (CGFloat)inset {
//    return 0;
    UICollectionView* cv = self.collectionView;
    CGFloat height = (cv.height - cv.verticalContentInsets);
    return MAX(0, height - cv.contentSize.height);
}

- (CGAffineTransform)adjustmentTransform:(CGFloat)inset {
    NSLog(@"inset = %f", inset);
    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI);
    if (inset > 0) {
        transform = CGAffineTransformTranslate(transform, 0, -inset);
    }
    return transform;
}

- (UICollectionViewLayoutAttributes *)adjustAttributes:(UICollectionViewLayoutAttributes *)attributes transform:(CGAffineTransform)transform {
	if (!CGAffineTransformEqualToTransform(attributes.transform, transform)) {
		attributes.transform = transform;
	}
	return attributes;
}

//- (void)prepareLayout {
//    [super prepareLayout];
//    NSArray* attributes = [self layoutAttributesForElementsInRect:self.collectionView.bounds];
//    CGAffineTransform transform = [self adjustmentTransform:self.inset];
//    for (UICollectionViewLayoutAttributes* attr in attributes) {
//        [self adjustAttributes:attr transform:transform];
//    }
//}

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

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
    UICollectionViewFlowLayoutInvalidationContext* context = (id)[super invalidationContextForBoundsChange:newBounds];
    if (!context.invalidateEverything) {
        context.invalidateFlowLayoutDelegateMetrics = YES;
        context.invalidateFlowLayoutAttributes = YES;
    }
    return context;
}

@end
