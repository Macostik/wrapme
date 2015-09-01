//
//  WLCollectionViewFlowLayout.h
//  moji
//
//  Created by Ravenpod on 4/11/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLCollectionViewFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, readonly) CGFloat inset;

@property (strong, nonatomic) NSMutableSet* animatingIndexPaths;

- (void)invalidate;

@end
