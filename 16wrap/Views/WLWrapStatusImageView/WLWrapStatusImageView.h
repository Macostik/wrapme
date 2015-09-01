//
//  WLWrapStatusImageView.h
//  Wrap
//
//  Created by Sergey Maximenko on 8/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLCircleImageView.h"

static NSString *WLWrapStatusFollowerImage = @"%";
static NSString *WLWrapStatusOwnerImage = @"'";

@interface WLWrapStatusImageView : WLImageView

@property (weak, nonatomic) IBOutlet UILabel *statusView;

@property (nonatomic) BOOL isFollowed;

@property (nonatomic) BOOL isOwner;

@end
