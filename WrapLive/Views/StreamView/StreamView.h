//
//  PICStreamView.h
//  Riot
//
//  Created by Sergey Maximenko on 21.02.13.
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

typedef NS_ENUM(NSUInteger, StreamViewReusableViewLoadingType)
{
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
- (CGFloat)streamViewSpacing:(StreamView*)streamView;
- (void)streamViewDidRefreshData:(StreamView*)streamView;
- (void)streamViewDidLoadData:(StreamView*)streamView;
- (UIView*)streamView:(StreamView*)streamView supplementaryViewInSection:(NSInteger)section;
- (CGFloat)streamView:(StreamView*)streamView ratioForSupplementaryViewInSection:(NSInteger)section;
- (CGFloat)streamView:(StreamView*)streamView initialRangeForColumn:(NSInteger)column;

@end

@interface StreamView : UIScrollView

@property (nonatomic, unsafe_unretained) IBOutlet id <StreamViewDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIView* headerView;

@property (nonatomic, strong) StreamLayout* layout;

@property (nonatomic) StreamViewReusableViewLoadingType reusableViewLoadingType;

- (StreamLayoutItem*)visibleItemAtPoint:(CGPoint)point;
- (void)reloadData;
- (void)reloadData:(BOOL)stop;
- (void)clearData;
- (id)reusableViewOfClass:(Class)viewClass;
- (id)reusableViewOfClass:(Class)viewClass forItem:(StreamLayoutItem*)item;;

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

@property (nonatomic) BOOL isSupplementary;

@end
