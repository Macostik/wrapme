//
//  WLCollectionViewFlowLayout.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 4/11/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic) CGFloat inset;

@property (nonatomic) CGFloat typingInset;

@property (strong, nonatomic) UIView* loadingView;

@end
