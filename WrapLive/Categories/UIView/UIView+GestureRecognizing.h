//
//  UIView+GestureRecognizing.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLBlocks.h"

@interface UIView (GestureRecognizing)

- (void)addTapGestureRecognizing:(WLPointBlock)block;

- (void)removeTapGestureRecognizing;

- (void)addLongPressGestureRecognizing:(WLPointBlock)block;

@end
