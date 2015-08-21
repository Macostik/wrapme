//
//  StreamMetrics.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@class StreamIndex;
@class StreamMetrics;
@class StreamItem;
@class StreamView;
@class StreamReusableView;

typedef void(^StreamMetricsBlock)(StreamMetrics *metrics);
typedef void(^StreamMetricsViewBeforeSetupBlock)(StreamItem *item, id view, id entry);
typedef void(^StreamMetricsViewAfterSetupBlock)(StreamItem *item, id view, id entry);

@interface StreamMetrics : NSObject

@property (strong, nonatomic) IBInspectable NSString *identifier;

@property (strong, nonatomic) UINib *nib;

@property (nonatomic) BOOL hidden;

@property (strong, nonatomic) BOOL(^hiddenBlock)(StreamIndex *index);

@property (nonatomic) IBInspectable CGFloat size;

@property (strong, nonatomic) CGFloat(^sizeBlock)(StreamIndex *index);

@property (nonatomic) IBInspectable UIEdgeInsets insets;

@property (strong, nonatomic) UIEdgeInsets(^insetsBlock)(StreamIndex *index);

@property (strong, nonatomic) WLObjectBlock selectionBlock;

+ (instancetype)metrics:(StreamMetricsBlock)block;

- (instancetype)change:(StreamMetricsBlock)block;

- (id)viewForItem:(StreamItem*)item inStreamView:(StreamView*)streamView entry:(id)entry;

- (void)setViewBeforeSetupBlock:(StreamMetricsViewBeforeSetupBlock)viewBeforeSetupBlock;

- (void)setViewAfterSetupBlock:(StreamMetricsViewAfterSetupBlock)viewAfterSetupBlock;

- (void)setHiddenBlock:(BOOL (^)(StreamIndex *index))hiddenBlock;

- (BOOL)hiddenAt:(StreamIndex*)index;

- (void)setSizeBlock:(CGFloat (^)(StreamIndex *index))sizeBlock;

- (CGFloat)sizeAt:(StreamIndex*)index;

- (void)setInsetsBlock:(UIEdgeInsets (^)(StreamIndex *index))insetsBlock;

- (UIEdgeInsets)insetsAt:(StreamIndex*)index;

@end
