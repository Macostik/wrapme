//
//  WLLoadingView.h
//  moji
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString* WLLoadingViewIdentifier = @"WLLoadingView";
static CGFloat WLLoadingViewDefaultSize = 66.0f;

@interface WLLoadingView : UICollectionReusableView

@property (nonatomic) BOOL animating;

@property (nonatomic) BOOL error;

+ (instancetype)instance;

+ (instancetype)splash;

+ (void)registerInCollectionView:(UICollectionView*)collectionView;

+ (instancetype)dequeueInCollectionView:(UICollectionView*)collectionView indexPath:(NSIndexPath*)indexPath;

- (instancetype)showInView:(UIView*)view;

- (void)hide;

@end
