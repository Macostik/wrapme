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

typedef CGFloat(^StreamMetricsFloatBlock)(StreamIndex *index);
typedef BOOL(^StreamMetricsBoolBlock)(StreamIndex *index);
typedef NSString*(^StreamMetricsStringBlock)(StreamIndex *index);
typedef void(^StreamMetricsBlock)(StreamMetrics *metrics);

@interface StreamMetricsFloatProperty : NSObject

@property (nonatomic) CGFloat value;

@property (strong, nonatomic) StreamMetricsFloatBlock block;

- (CGFloat)valueAt:(StreamIndex*)index;

@end

@interface StreamMetricsBoolProperty : NSObject

@property (nonatomic) BOOL value;

@property (strong, nonatomic) StreamMetricsBoolBlock block;

- (BOOL)valueAt:(StreamIndex*)index;

@end

@interface StreamMetricsStringProperty : NSObject

@property (strong, nonatomic) NSString *value;

@property (strong, nonatomic) StreamMetricsStringBlock block;

- (NSString*)valueAt:(StreamIndex*)index;

@end

@interface StreamMetrics : NSObject

@property (strong, nonatomic) NSString *identifier;

@property (strong, nonatomic) UINib *nib;

@property (strong, nonatomic) StreamMetricsBoolProperty *hidden;

@property (strong, nonatomic) StreamMetricsFloatProperty *size;

@property (strong, nonatomic) NSMutableArray *headers;

@property (strong, nonatomic) NSMutableArray *footers;

+ (instancetype)metrics:(StreamMetricsBlock)block;

- (instancetype)addHeader:(StreamMetricsBlock)block;

- (instancetype)addFooter:(StreamMetricsBlock)block;

@end
