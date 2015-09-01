//
//  StreamCell.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StreamMetrics.h"

@interface StreamReusableView : UIView

@property (strong, nonatomic) id entry;

@property (strong, nonatomic) WLObjectBlock selectionBlock;

@property (strong, nonatomic) StreamMetrics *metrics;

@property (nonatomic) BOOL selected;

- (void)prepareForReuse;

- (void)setup:(id)entry;

- (void)resetup;

- (void)select:(id)entry;

@end
