//
//  StreamCell.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLEntrySetup.h"

@class StreamMetrics;

@interface StreamReusableView : UIView <WLEntrySetup>

@property (strong, nonatomic) StreamMetrics *metrics;

@property (nonatomic) BOOL selected;

- (void)prepareForReuse;

@end
