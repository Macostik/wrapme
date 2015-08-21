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

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *headerMetrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *sectionHeaderMetrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *metrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *sectionFooterMetrics;

@property (strong, nonatomic) IBOutletCollection(StreamMetrics) NSMutableArray *footerMetrics;

@property (strong, nonatomic) IBInspectable NSString *itemIdentifier;

@property (nonatomic) IBInspectable CGFloat itemSize;

@property (nonatomic) IBInspectable UIEdgeInsets itemInsets;

@property (nonatomic) ScrollDirection direction;

@property (strong, nonatomic) NSUInteger (^numberOfItemsBlock) (id dataSource);

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
