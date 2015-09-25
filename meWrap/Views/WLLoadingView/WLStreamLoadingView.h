//
//  WLStreamLoadingView.h
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

static NSString* WLStreamLoadingViewIdentifier = @"WLStreamLoadingView";
static CGFloat WLStreamLoadingViewDefaultSize = 66.0f;

@interface WLStreamLoadingView : StreamReusableView

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView* spinner;

@property (nonatomic) BOOL animating;

+ (StreamMetrics*)streamLoadingMetrics;

@end
