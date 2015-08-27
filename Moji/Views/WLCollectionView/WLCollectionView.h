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
} WLPlaceholderMode;

@interface WLCollectionView : UICollectionView

@property (strong, nonatomic) IBInspectable NSString *nibNamePlaceholder;

@property (strong, nonatomic) NSString *placeholderText;

@property (assign, nonatomic) WLPlaceholderMode mode;

+ (void)lock;

+ (void)unlock;

- (void)lock;

- (void)unlock;

- (BOOL)isDefaultPlaceholder;

- (void)setDefaulPlaceholder;

- (void)addToCachePlaceholderWithName:(NSString *)placeholderName byType:(NSInteger)type;

- (void)setPlaceholderByType:(NSInteger)type;

@end
