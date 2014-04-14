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

- (void)dealloc {
	[self.collectionView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)awakeFromNib {
	[super awakeFromNib];
	[self.collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if (self.collectionView.contentSize.height < self.collectionView.height) {
		self.inset = self.collectionView.height - self.collectionView.contentSize.height;
	} else {
		self.inset =  0;
	}
	[self updateLoadingViewPosition];
}

- (void)updateLoadingViewPosition {
	if (self.loadingView) {
		CGFloat position = self.collectionView.contentSize.height;
		if (position != self.loadingView.y) {
			self.loadingView.height = (_inset == 0 ? 66 : _inset);
			self.loadingView.y = self.collectionView.contentSize.height;
		}
	}
}

- (void)setLoadingView:(UIView *)loadingView {
	[_loadingView removeFromSuperview];
	_loadingView = loadingView;
	UIEdgeInsets insets = self.collectionView.contentInset;
	if (loadingView) {
		[self.collectionView addSubview:loadingView];
		[self updateLoadingViewPosition];
		insets.bottom = self.loadingView.height;
	} else {
		insets.bottom = 0;
	}
	self.collectionView.contentInset = insets;
}

- (void)setInset:(CGFloat)inset {
	if (_inset != inset) {
		_inset = inset;
		[self invalidateLayout];
	}
}

- (UICollectionViewLayoutAttributes *)adjustAttributes:(UICollectionViewLayoutAttributes *)attributes {
	CGAffineTransform transform;
	if (self.inset == 0) {
		transform = CGAffineTransformMakeRotation(M_PI);
	} else {
		transform = CGAffineTransformTranslate(CGAffineTransformMakeRotation(M_PI), 0, -self.inset);
	}
	if (!CGAffineTransformEqualToTransform(attributes.transform, transform)) {
		attributes.transform = transform;
	}
	return attributes;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
	return [self adjustAttributes:[super layoutAttributesForItemAtIndexPath:indexPath]];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
	return [self adjustAttributes:[super layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath]];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
	NSArray* attributes = [super layoutAttributesForElementsInRect:rect];
	for (UICollectionViewLayoutAttributes* attr in attributes) {
		[self adjustAttributes:attr];
	}
	return attributes;
}
//
//- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
//	return YES;
//}

@end
