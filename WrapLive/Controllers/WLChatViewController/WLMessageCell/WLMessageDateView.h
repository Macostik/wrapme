//
//  WLMessageDateView.h
//  WrapLive
//
//  Created by Sergey Maximenko on 2/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLMessage;

@interface WLMessageDateView : UICollectionReusableView

@property (strong, nonatomic) WLMessage* message;

@end
