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

- (BOOL)isDefaultPlaceholder;
- (void)setDefaulPlaceholder;
- (void)setPlaceholderWithName:(NSString *)placeholderName byType:(NSInteger)type;

@end
