//
//  PICStreamLayout.h
//  RIOT
//
//  Created by Ravenpod on 09.10.13.
//  Copyright (c) 2013 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StreamView.h"

@class StreamItem, StreamLayout;

@protocol StreamLayoutDelegate <StreamViewDelegate>

@optional

- (CGFloat)streamView:(StreamView*)streamView layoutOffset:(StreamLayout*)layout;

@end

@interface StreamLayout : NSObject

@property (nonatomic, weak) StreamView* streamView;

@property (nonatomic, readonly) CGSize contentSize;

@property (nonatomic) IBInspectable BOOL horizontal;

- (void)prepare;

- (StreamItem*)layout:(StreamItem*)item;

- (void)prepareForNextSection;

- (void)finalize;

@end