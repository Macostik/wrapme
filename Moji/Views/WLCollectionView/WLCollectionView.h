//
//  WLCollectionView.h
//  moji
//
//  Created by Ravenpod on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLLabel.h"

typedef enum : NSUInteger {
    WLDefaultPlaceholderMode,
    WLManualPlaceholderMode,
} WLPlacehoderMode;

@interface WLCollectionView : UICollectionView

@property (strong, nonatomic) IBInspectable NSString *nibNamePlaceholder;
@property (strong, nonatomic) NSString *placeholderText;

- (BOOL)isDefaultPlaceholder;
- (void)setDefaulPlaceholder;
- (void)addToCachePlaceholderWithName:(NSString *)placeholderName byType:(NSInteger)type;
- (void)setPlaceholderByTupe:(NSInteger)type;

- (void)lockReloadingData;

- (void)unlockReloadingData;

@end
