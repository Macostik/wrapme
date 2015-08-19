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

typedef CGFloat(^StreamMetricsFloatBlock)(StreamIndex *index);
typedef BOOL(^StreamMetricsBoolBlock)(StreamIndex *index);
typedef NSString*(^StreamMetricsStringBlock)(StreamIndex *index);
typedef void(^StreamMetricsBlock)(StreamMetrics *metrics);
typedef void(^StreamMetricsViewBeforeSetupBlock)(StreamItem *item, id view, id entry);
typedef void(^StreamMetricsViewAfterSetupBlock)(StreamItem *item, id view, id entry);

@interface StreamMetricsFloatProperty : NSObject

@property (nonatomic) CGFloat value;

@property (strong, nonatomic) StreamMetricsFloatBlock block;

- (void)setBlock:(StreamMetricsFloatBlock)block;

- (CGFloat)valueAt:(StreamIndex*)index;

@end

@interface StreamMetricsBoolProperty : NSObject

@property (nonatomic) BOOL value;

@property (strong, nonatomic) StreamMetricsBoolBlock block;

- (void)setBlock:(StreamMetricsBoolBlock)block;

- (BOOL)valueAt:(StreamIndex*)index;

@end

@interface StreamMetricsStringProperty : NSObject

@property (strong, nonatomic) NSString *value;

@property (strong, nonatomic) StreamMetricsStringBlock block;

- (void)setBlock:(StreamMetricsStringBlock)block;

- (NSString*)valueAt:(StreamIndex*)index;

@end

@interface StreamMetrics : NSObject

@property (strong, nonatomic) IBInspectable NSString *identifier;

@property (strong, nonatomic) UINib *nib;

@property (strong, nonatomic) StreamMetricsBoolProperty *hidden;

@property (strong, nonatomic) StreamMetricsFloatProperty *size;

@property (strong, nonatomic) StreamMetricsFloatProperty *topSpacing;

@property (strong, nonatomic) StreamMetricsFloatProperty *bottomSpacing;

@property (strong, nonatomic) NSMutableArray *headers;

@property (strong, nonatomic) NSMutableArray *footers;

@property (strong, nonatomic) WLObjectBlock selectionBlock;

+ (instancetype)metrics:(StreamMetricsBlock)block;

- (instancetype)addHeader:(StreamMetricsBlock)block;

- (instancetype)addFooter:(StreamMetricsBlock)block;

- (id)viewForItem:(StreamItem*)item inStreamView:(StreamView*)streamView entry:(id)entry;

- (void)setViewBeforeSetupBlock:(StreamMetricsViewBeforeSetupBlock)viewBeforeSetupBlock;

- (void)setViewAfterSetupBlock:(StreamMetricsViewAfterSetupBlock)viewAfterSetupBlock;

@end
