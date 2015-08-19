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

- (StreamMetrics*)streamView:(StreamView*)streamView metricsAt:(StreamIndex*)index;

@optional

- (NSInteger)streamViewNumberOfSections:(StreamView*)streamView;

- (void)streamView:(StreamView*)streamView didSelectItem:(StreamItem*)item;

@end

@interface StreamView : UIScrollView

@property (nonatomic, weak) IBOutlet id <StreamViewDelegate> delegate;

@property (nonatomic, strong) IBOutlet StreamLayout* layout;

@property (weak, nonatomic) StreamItem *selectedItem;

- (StreamItem*)visibleItemAtPoint:(CGPoint)point;

+ (void)lock;

+ (void)unlock;

- (void)lock;

- (void)unlock;

- (void)reload;

- (void)clear;

- (id)viewForItem:(StreamItem*)item;

@end
