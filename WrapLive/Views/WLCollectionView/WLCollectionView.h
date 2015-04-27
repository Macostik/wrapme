//
//  WLCollectionView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WLCollectionView : UICollectionView

@property (nonatomic) BOOL stopReloadingData;

@property (strong, nonatomic) IBInspectable NSString *nibNamePlaceholder;

- (BOOL)isDefaultPlaceholder;
- (void)setDefaulPlaceholder;
- (void)addToCachePlaceholderWithName:(NSString *)placeholderName byType:(NSInteger)type;
- (void)setPlaceholderByTupe:(NSInteger)type;

@end
