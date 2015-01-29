//
//  WLScrollView.h
//  WrapLive
//
//  Created by Yura Granchenko on 26/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLScrollView;

@protocol WLScrollViewDelegate <NSObject>

- (void)scrollViewWillBeginZooming:(WLScrollView *)scrollView;

@end

@interface WLScrollView : UIScrollView <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView* zoomingView;

@property (strong, nonatomic) IBOutlet id <WLScrollViewDelegate> scrollDelegate;

@end
