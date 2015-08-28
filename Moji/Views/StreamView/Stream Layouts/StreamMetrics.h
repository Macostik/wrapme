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
typedef void(^StreamMetricsEntryBlock)(StreamItem *item, id entry);

@interface StreamMetrics : NSObject

@property (strong, nonatomic) IBInspectable NSString *identifier;

@property (strong, nonatomic) UINib *nib;

@property (weak, nonatomic) IBOutlet id nibOwner;

@property (nonatomic) IBInspectable BOOL hidden;

@property (strong, nonatomic) BOOL(^hiddenBlock)(StreamIndex *index, StreamMetrics *metrics);

@property (nonatomic) IBInspectable CGFloat size;

@property (strong, nonatomic) CGFloat(^sizeBlock)(StreamIndex *index, StreamMetrics *metrics);

@property (nonatomic) IBInspectable CGRect insets;

@property (strong, nonatomic) CGRect(^insetsBlock)(StreamIndex *index, StreamMetrics *metrics);

@property (strong, nonatomic) StreamMetricsEntryBlock selectionBlock;

@property (strong, nonatomic) StreamMetricsEntryBlock viewWillAppearBlock;

@property (strong, nonatomic) NSMutableSet *reusableViews;

+ (instancetype)metrics:(StreamMetricsBlock)block;

- (instancetype)change:(StreamMetricsBlock)block;

- (void)setViewWillAppearBlock:(StreamMetricsEntryBlock)viewWillAppearBlock;

- (void)setHiddenBlock:(BOOL (^)(StreamIndex *index, StreamMetrics *metrics))hiddenBlock;

- (BOOL)hiddenAt:(StreamIndex*)index;

- (void)setSizeBlock:(CGFloat (^)(StreamIndex *index, StreamMetrics *metrics))sizeBlock;

- (CGFloat)sizeAt:(StreamIndex*)index;

- (void)setInsetsBlock:(CGRect (^)(StreamIndex *index, StreamMetrics *metrics))insetsBlock;

- (CGRect)insetsAt:(StreamIndex*)index;

- (StreamReusableView*)loadView;

- (void)select:(StreamItem*)item entry:(id)entry;

- (void)setSelectionBlock:(StreamMetricsEntryBlock)selectionBlock;

@end
