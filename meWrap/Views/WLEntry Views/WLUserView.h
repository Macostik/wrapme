//
//  WLUserView.h
//  meWrap
//
//  Created by Ravenpod on 6/4/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryView.h"

@class WLImageView;

@interface WLUserView : WLEntryView

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
