//
//  StreamViewDataSource.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamView.h"
#import "GridLayout.h"
#import "WLRefresher.h"

typedef NS_ENUM(NSUInteger, ScrollDirection) {
    ScrollDirectionUnknown,
    ScrollDirectionUp,
    ScrollDirectionDown
};

@interface StreamDataSource : NSObject <GridLayoutDelegate, StreamLayoutDelegate>

@property (weak, nonatomic) IBOutlet StreamView *streamView;

@property (strong, nonatomic) id <WLBaseOrderedCollection> items;

@property (weak, nonatomic, readonly) StreamMetrics *autogeneratedMetrics;

@property (strong, nonatomic, readonly) StreamMetrics *autogeneratedPlaceholderMetrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *headerMetrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *sectionHeaderMetrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *metrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *sectionFooterMetrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *footerMetrics;

@property (strong, nonatomic) IBInspectable NSString *itemIdentifier;

@property (weak, nonatomic) IBOutlet id itemNibOwner;

@property (nonatomic) IBInspectable CGFloat itemSize;

@property (nonatomic) IBInspectable CGRect itemInsets;

@property (strong, nonatomic) IBInspectable NSString *placeholderIdentifier;

@property (nonatomic) ScrollDirection direction;

@property (strong, nonatomic) NSUInteger (^numberOfItemsBlock) (id dataSource);

@property (nonatomic) IBInspectable CGFloat layoutOffset;

@property (nonatomic) IBInspectable CGFloat layoutSpacing;

@property (strong, nonatomic) CGFloat(^layoutOffsetBlock)(void);

@property (nonatomic) IBInspectable NSUInteger numberOfGridColumns;

@property (strong, nonatomic) NSUInteger(^numberOfGridColumnsBlock)(void);

@property (nonatomic) IBInspectable CGFloat sizeForGridColumns;

@property (strong, nonatomic) CGFloat(^sizeForGridColumnBlock)(NSUInteger column);

@property (nonatomic) IBInspectable CGFloat offsetForGridColumns;

@property (strong, nonatomic) CGFloat(^offsetForGridColumnBlock)(NSUInteger column);

- (void)setLayoutOffsetBlock:(CGFloat (^)(void))layoutOffsetBlock;

- (void)setNumberOfGridColumns:(NSUInteger)numberOfGridColumns;

- (void)setSizeForGridColumnBlock:(CGFloat (^)(NSUInteger column))sizeForGridColumnBlock;

- (void)setOffsetForGridColumnBlock:(CGFloat (^)(NSUInteger column))offsetForGridColumnBlock;

- (void)didAwake;

- (void)reload;

- (void)refresh;

- (void)refresh:(WLRefresher*)sender;

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)setRefreshable;

- (void)setRefreshableWithStyle:(WLRefresherStyle)style contentMode:(UIViewContentMode)contentMode;

- (void)setRefreshableWithContentMode:(UIViewContentMode)contentMode;

- (void)setRefreshableWithStyle:(WLRefresherStyle)style;

- (StreamMetrics*)addHeaderMetrics:(StreamMetrics*)metrics;

- (StreamMetrics*)addSectionHeaderMetrics:(StreamMetrics*)metrics;

- (StreamMetrics*)addMetrics:(StreamMetrics*)metrics;

- (StreamMetrics*)addSectionFooterMetrics:(StreamMetrics*)metrics;

- (StreamMetrics*)addFooterMetrics:(StreamMetrics*)metrics;

@end
