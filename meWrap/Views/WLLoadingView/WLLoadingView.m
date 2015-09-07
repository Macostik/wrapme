//
//  WLLoadingView.m
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLLoadingView.h"
#import "NSObject+NibAdditions.h"

@interface WLLoadingView ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* spinner;

@property (weak, nonatomic) IBOutlet UIView* errorView;

@end

@implementation WLLoadingView

+ (instancetype)instance {
    return [self loadFromNib];
}

+ (instancetype)splash {
    return [self loadFromNibNamed:@"WLSplashLoadingView"];
}

+ (void)registerInCollectionView:(UICollectionView *)collectionView {
    [collectionView registerNib:[self nib] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WLLoadingViewIdentifier];
}

+ (instancetype)dequeueInCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath *)indexPath {
    return [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:WLLoadingViewIdentifier forIndexPath:indexPath];
}

- (BOOL)animating {
    return self.spinner.isAnimating;
}

- (void)setAnimating:(BOOL)animating {
    if (self.animating) {
        [self.spinner stopAnimating];
    } else {
        [self.spinner startAnimating];
    }
}

- (void)setError:(BOOL)error {
    _error = error;
    self.errorView.hidden = !error;
    self.spinner.hidden = error;
}

- (instancetype)showInView:(UIView*)view {
    self.frame = view.bounds;
    [view addSubview:self];
    return self;
}

- (void)hide {
    [self removeFromSuperview];
}

@end
