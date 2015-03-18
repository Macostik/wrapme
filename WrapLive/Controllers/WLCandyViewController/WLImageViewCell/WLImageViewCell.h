//
//  WLImageViewCell.h
//  WrapLive
//
//  Created by Yura Granchenko on 26/01/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLEntryCell.h"

static NSString *WLImageViewCellIdentifier = @"WLImageViewCell";

@interface WLImageViewCell : WLEntryCell

@property (weak, nonatomic, readonly) IBOutlet UIScrollView *scrollView;

@end

