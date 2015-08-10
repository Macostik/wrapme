//
//  WLNavigationAnimator.h
//  moji
//
//  Created by Ravenpod on 12/1/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WLNavigationAnimatorPresentationType) {
    WLNavigationAnimatorPresentationTypeDefault,
    WLNavigationAnimatorPresentationTypeModal
};

@interface WLNavigationAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic) BOOL presenting;

@end

@interface UIViewController (WLNavigationAnimator)

@property (nonatomic) WLNavigationAnimatorPresentationType animatorPresentationType;

@end
