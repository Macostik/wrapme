//
//  WLCollectionView.h
//  moji
//
//  Created by Ravenpod on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLLabel.h"

@interface WLCollectionView : UICollectionView

@property (strong, nonatomic) IBInspectable NSString *nibNamePlaceholder;

@property (strong, nonatomic) NSString *placeholderText;

@property (assign, nonatomic) NSInteger index;

+ (void)lock;

+ (void)unlock;

- (void)lock;

- (void)unlock;

@end
