//
//  UINavigationController+InterfaceOrientation.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/19/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UINavigationController+InterfaceOrientation.h"

@implementation UINavigationController (InterfaceOrientation)

- (BOOL)shouldAutorotate {
    return [self.topViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
