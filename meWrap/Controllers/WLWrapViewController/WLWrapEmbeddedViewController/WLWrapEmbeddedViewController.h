//
//  WLWrapEmbeddedViewController.h
//  meWrap
//
//  Created by Ravenpod on 7/10/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@class WLWrapEmbeddedViewController, WLBadgeLabel;

@protocol WLWrapEmbeddedViewControllerDelegate <NSObject>

@end

@interface WLWrapEmbeddedViewController : WLBaseViewController

@property (nonatomic, weak) id <WLWrapEmbeddedViewControllerDelegate> delegate;

@property (weak, nonatomic) Wrap *wrap;

@property (weak, nonatomic) WLBadgeLabel* badge;

@property (copy, nonatomic) WLObjectBlock typingHalper;

@end
