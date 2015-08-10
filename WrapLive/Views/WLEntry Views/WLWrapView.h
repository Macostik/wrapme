//
//  WLWrapView.h
//  moji
//
//  Created by Ravenpod on 2/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLEntryView.h"

@class WLImageView;

@interface WLWrapView : WLEntryView

@property (weak, nonatomic) IBOutlet WLImageView *coverView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
