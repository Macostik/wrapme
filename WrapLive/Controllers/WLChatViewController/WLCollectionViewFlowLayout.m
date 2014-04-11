//
//  WLCollectionViewFlowLayout.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/11/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCollectionViewFlowLayout.h"

@implementation WLCollectionViewFlowLayout

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes* attributes = [super layoutAttributesForItemAtIndexPath:indexPath];
	attributes.transform = CGAffineTransformMakeRotation(M_PI);
	return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	UICollectionViewLayoutAttributes* attributes = [super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
	attributes.transform = CGAffineTransformMakeRotation(M_PI);
	return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSArray* attributes = [super layoutAttributesForElementsInRect:rect];
	
	for (UICollectionViewLayoutAttributes* attr in attributes) {
		attr.transform = CGAffineTransformMakeRotation(M_PI);
	}
	
	return attributes;
}

@end
