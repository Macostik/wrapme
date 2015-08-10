//
//  PICStreamView.h
//  Riot
//
//  Created by Ravenpod on 21.02.13.
//
//

#import <UIKit/UIKit.h>

@class StreamView;
@class StreamLayoutItem;
@class StreamLayout;

typedef struct {
    NSInteger section;
    NSInteger row;
} StreamIndex;

typedef NS_ENUM(NSUInteger, StreamViewReusableViewLoadingType) {
    StreamViewReusableViewLoadingTypeNone,
    StreamViewReusableViewLoadingTypeInit,
    StreamViewReusableViewLoadingTypeNib
};

@protocol StreamViewDelegate <UIScrollViewDelegate>

- (NSInteger)streamView:(StreamView*)streamView numberOfItemsInSection:(NSInteger)section;
- (UIView*)streamView:(StreamView*)streamView viewForItem:(StreamLayoutItem*)item;
- (CGFloat)streamView:(StreamView*)streamView ratioForItemAtIndex:(StreamIndex)index;

@optional
- (NSInteger)streamViewNumberOfColumns:(StreamView*)streamView;
- (NSInteger)streamViewNumberOfSections:(StreamView*)streamView;
- (void)streamView:(StreamView*)streamView didSelectItem:(StreamLayoutItem*)item;
- (CGFloat)streamView:(StreamView*)streamView initialRangeForColumn:(NSInteger)column;
- (CGFloat)streamView:(StreamView*)streamView sizeForColumn:(NSInteger)column;

@end

@interface StreamView : UIScrollView

@property (nonatomic, weak) IBOutlet id <StreamViewDelegate> delegate;

@property (nonatomic, strong) StreamLayout* layout;

@property (nonatomic) StreamViewReusableViewLoadingType reusableViewLoadingType;

- (StreamLayoutItem*)visibleItemAtPoint:(CGPoint)point;
- (void)reloadData;
- (void)clearData;
- (id)reusableViewOfClass:(Class)viewClass;
- (id)reusableViewOfClass:(Class)viewClass forItem:(StreamLayoutItem*)item;
- (id)reusableViewOfClass:(Class)viewClass forItem:(StreamLayoutItem*)item loadingType:(StreamViewReusableViewLoadingType)loadingType;

@end

@protocol StreamLayoutItemDelegate <NSObject>

- (void)streamLayoutItemWillBecomeInvisible:(StreamLayoutItem*)item;
- (void)streamLayoutItemWillBecomeVisible:(StreamLayoutItem*)item;

@end

@interface StreamLayoutItem : NSObject

@property (nonatomic, weak) id <StreamLayoutItemDelegate> delegate;

@property (weak, nonatomic) UIView* view;
@property (unsafe_unretained, nonatomic) CGRect frame;
@property (unsafe_unretained, nonatomic) BOOL visible;
@property (unsafe_unretained, nonatomic) StreamIndex index;

@end
