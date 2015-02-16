//
//  WLCollectionView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    WLDefaultPlaceholderMode,
    WLManualPlaceholderMode,
} WLPlacehoderMode;

@interface WLCollectionView : UICollectionView

@property (strong, nonatomic) IBInspectable NSString *nibNamePlaceholder;
@property (strong, nonatomic) IBInspectable NSString *modeNibNamePlaceholder;
@property (assign, nonatomic) WLPlacehoderMode placeholderMode;

@end
