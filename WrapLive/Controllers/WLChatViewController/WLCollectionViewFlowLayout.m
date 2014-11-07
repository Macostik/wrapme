//
//  WLCollectionViewFlowLayout.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/11/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCollectionViewFlowLayout.h"
#import "UIView+Shorthand.h"

@implementation WLCollectionViewFlowLayout

- (CGFloat)inset {
    CGFloat inset = MAX(0, self.collectionView.height - self.collectionView.contentSize.height);
    if (inset < self.collectionView.height) {
        return inset;
    }
    return 0;
}

- (UICollectionViewLayoutAttributes *)adjustAttributes:(UICollectionViewLayoutAttributes *)attributes inset:(CGFloat)inset {
	CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI);
	if (inset > 0) {
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

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return YES;
}

//- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds {
//    UICollectionViewFlowLayoutInvalidationContext* context = (id)[super invalidationContextForBoundsChange:newBounds];
//    if (!context.invalidateEverything) {
//        context.invalidateFlowLayoutDelegateMetrics = YES;
//        context.invalidateFlowLayoutAttributes = YES;
//    }
//    return context;
//}

@end
