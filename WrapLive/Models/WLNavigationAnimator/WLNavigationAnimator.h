//
//  WLNavigationAnimator.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WLNavigationAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) BOOL modal;

@property (nonatomic) BOOL presenting;

@end
