//
//  WLTimelineHeaderView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLTimelineEvent;

@interface WLTimelineEventHeaderView : UICollectionReusableView

@property (strong, nonatomic) WLTimelineEvent* event;

@end
