//
//  WLMessageDateView.h
//  moji
//
//  Created by Ravenpod on 2/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class WLMessage;

@interface WLMessageDateView : StreamReusableView

@property (strong, nonatomic) WLMessage* message;

@end
