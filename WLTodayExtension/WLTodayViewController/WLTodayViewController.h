//
//  WLTodayViewController.h
//  WLTodayExtension
//
//  Created by Yura Granchenko on 11/27/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^WLObjectBlock) (id object);

@interface WLTodayViewController : UIViewController

@property (strong, nonatomic) WLObjectBlock selection;

@end
