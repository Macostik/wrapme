//
//  WLSizeToFitLabel.h
//  WrapLive
//
//  Created by Yura Granchenko on 9/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//
typedef NS_OPTIONS(NSUInteger, VerticalAlignment) {
    VerticalAlignmentTop      = 0,
    VerticalAlignmentMiddle   = 1 << 0,
    VerticalAlignmentBottom   = 1 << 1,
};

#import <UIKit/UIKit.h>

@interface WLSizeToFitLabel : UILabel

@property (nonatomic, assign) VerticalAlignment verticalAlignment;

@property (assign, nonatomic) NSInteger intValue;

@end
