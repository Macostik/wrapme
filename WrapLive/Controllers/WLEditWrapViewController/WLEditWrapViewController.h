//
//  WLEditWrapViewController.h
//  WrapLive
//
//  Created by Yura Granchenko on 9/9/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditWrapViewController.h"
#import "WLActionViewController.h"

@interface WLEditWrapViewController : WLEditViewController

@property (strong, nonatomic) WLWrap *wrap;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end
