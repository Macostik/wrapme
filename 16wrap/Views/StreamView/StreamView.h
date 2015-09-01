//
//  PICStreamView.h
//  Riot
//
//  Created by Ravenpod on 21.02.13.
//
//

#import <UIKit/UIKit.h>
#import "StreamIndex.h"
#import "StreamMetrics.h"
#import "StreamItem.h"
#import "StreamReusableView.h"

@class StreamView;
@class StreamLayout;

@protocol StreamViewDelegate <UIScrollViewDelegate>

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section;

- (id)streamView:(StreamView*)streamView entryAt:(StreamIndex*)index;

- (NSArray*)streamView:(StreamView*)streamView metricsAt:(StreamIndex*)index;

@optional

- (NSArray*)streamViewHeaderMetrics:(StreamView*)streamView;

- (NSArray*)streamViewFooterMetrics:(StreamView*)streamView;

- (NSArray*)streamView:(StreamView*)streamView sectionHeaderMetricsInSection:(NSUInteger)section;

- (NSArray*)streamView:(StreamView*)streamView sectionFooterMetricsInSection:(NSUInteger)section;

- (StreamMetrics*)streamViewPlaceholderMetrics:(StreamView*)streamView;

- (NSInteger)streamViewNumberOfSections:(StreamView*)streamView;

@end

@interface StreamView : UIScrollView

@property (nonatomic, weak) IBOutlet id <StreamViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet StreamLayout* layout;

@property (weak, nonatomic) StreamItem *selectedItem;

@property (nonatomic) IBInspectable BOOL horizontal;

+ (void)lock;

+ (void)unlock;

- (void)lock;

- (void)unlock;

- (void)reload;

- (void)clear;

- (id)viewForItem:(StreamItem*)item;

- (StreamItem*)visibleItemAtPoint:(CGPoint)point;

- (StreamItem*)itemPassingTest:(BOOL(^)(StreamItem *item))test;

- (void)scrollToItem:(StreamItem*)item animated:(BOOL)animated;

@end
