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

- (id)streamView:(StreamView*)streamView viewForItem:(StreamItem*)item;

- (NSArray*)streamView:(StreamView*)streamView metricsAt:(StreamIndex*)index;

@optional

- (NSArray*)streamViewHeaderMetrics:(StreamView*)streamView;

- (NSArray*)streamViewFooterMetrics:(StreamView*)streamView;

- (NSArray*)streamView:(StreamView*)streamView sectionHeaderMetricsInSection:(NSUInteger)section;

- (NSArray*)streamView:(StreamView*)streamView sectionFooterMetricsInSection:(NSUInteger)section;

- (NSInteger)streamViewNumberOfSections:(StreamView*)streamView;

- (void)streamView:(StreamView*)streamView didSelectItem:(StreamItem*)item;

@end

@interface StreamView : UIScrollView

@property (nonatomic, weak) IBOutlet id <StreamViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet StreamLayout* layout;

@property (weak, nonatomic) StreamItem *selectedItem;

@property (nonatomic) IBInspectable BOOL horizontal;

- (StreamItem*)visibleItemAtPoint:(CGPoint)point;

+ (void)lock;

+ (void)unlock;

- (void)lock;

- (void)unlock;

- (void)reload;

- (void)clear;

- (id)viewForItem:(StreamItem*)item;

@end
