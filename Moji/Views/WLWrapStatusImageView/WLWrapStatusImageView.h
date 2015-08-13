//
//  WLWrapStatusImageView.h
//  Moji
//
//  Created by Sergey Maximenko on 8/13/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLCircleImageView.h"

@interface WLWrapStatusImageView : WLImageView

@property (weak, nonatomic) IBOutlet UIView *statusView;

@property (nonatomic) BOOL followed;

@end
