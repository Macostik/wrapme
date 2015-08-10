//
//  WLTouchView.h
//  moji
//
//  Created by Ravenpod on 3/17/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLTouchView;

@protocol WLTouchViewDelegate <NSObject>

@optional
- (void)touchViewDidReceiveTouch:(WLTouchView*)touchView;

- (NSSet*)touchViewExclusionRects:(WLTouchView*)touchView;

@end

@interface WLTouchView : UIView

@property (nonatomic, weak) IBOutlet id <WLTouchViewDelegate> delegate;

@end
