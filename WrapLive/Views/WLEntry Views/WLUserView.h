//
//  WLUserView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 6/4/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLEntryView.h"

@class WLUser;
@class WLImageView;

@interface WLUserView : WLEntryView

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@end
