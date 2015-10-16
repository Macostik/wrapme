//
//  WLComposerScrollView.m
//  meWrap
//
//  Created by Yura Granchenko on 15/10/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLComposerScrollView.h"

@implementation WLComposerScrollView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.contentOffset.y != 0) {
        [self setContentOffset:CGPointZero animated:YES];
        return NO;
    }  
    return YES;
}

@end
