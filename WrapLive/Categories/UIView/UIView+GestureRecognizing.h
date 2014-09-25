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

- (void)addTapGestureRecognizingDelegate:(id)delegate block:(WLGestureBlock)bloc;

- (void)addTapGestureRecognizing:(WLGestureBlock)block;

- (void)addSwipeGestureRecognizingDelegate:(id)delegate
                            direction:(UISwipeGestureRecognizerDirection)direction
                                block:(WLGestureBlock)block;

- (void)addSwipeGestureRecognizingDelegate:(id)delegate block:(WLGestureBlock)block;

- (void)addSwipeGestureRecognizing:(WLGestureBlock)block;

- (void)removeTapGestureRecognizing;

@end
