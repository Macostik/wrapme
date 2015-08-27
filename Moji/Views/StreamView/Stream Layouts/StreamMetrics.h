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
typedef void(^StreamMetricsViewWillAppearBlock)(StreamItem *item, id view, id entry);

@interface StreamMetrics : NSObject

@property (strong, nonatomic) IBInspectable NSString *identifier;

@property (strong, nonatomic) UINib *nib;

@property (weak, nonatomic) IBOutlet id nibOwner;

@property (nonatomic) BOOL hidden;

@property (strong, nonatomic) BOOL(^hiddenBlock)(StreamIndex *index);

@property (nonatomic) IBInspectable CGFloat size;

@property (strong, nonatomic) CGFloat(^sizeBlock)(StreamIndex *index);

@property (nonatomic) IBInspectable CGRect insets;

@property (strong, nonatomic) CGRect(^insetsBlock)(StreamIndex *index);

@property (strong, nonatomic) WLObjectBlock selectionBlock;

+ (instancetype)metrics:(StreamMetricsBlock)block;

- (instancetype)change:(StreamMetricsBlock)block;

- (id)viewForItem:(StreamItem*)item inStreamView:(StreamView*)streamView entry:(id)entry;

- (void)setViewWillAppearBlock:(StreamMetricsViewWillAppearBlock)viewWillAppearBlock;

- (void)setHiddenBlock:(BOOL (^)(StreamIndex *index))hiddenBlock;

- (BOOL)hiddenAt:(StreamIndex*)index;

- (void)setSizeBlock:(CGFloat (^)(StreamIndex *index))sizeBlock;

- (CGFloat)sizeAt:(StreamIndex*)index;

- (void)setInsetsBlock:(CGRect (^)(StreamIndex *index))insetsBlock;

- (CGRect)insetsAt:(StreamIndex*)index;

@end
