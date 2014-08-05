//
//  WLClearProgressBar.m
//  WrapLive
//
//  Created by Yura Granchenko on 8/5/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLClearProgressBar.h"
#import "UIView+Shorthand.h"
#import "UIColor+CustomColors.h"

@implementation WLClearProgressBar

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (UIView *)initializeBackgroundView {
    UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
	[backgroundView setFullFlexible];
	backgroundView.clipsToBounds = YES;
    backgroundView.backgroundColor = [UIColor WL_clearColor];
	return backgroundView;
}


@end
