//
//  WLSwipeViewController.h
//  WrapLive
//
//  Created by Sergey Maximenko on 05.09.13.
//  Copyright (c) 2013 Andrey Ivanov. All rights reserved.
//

#import "WLShakeViewController.h"

typedef void (^WLSwipeSelectionBlock)(id item);

@interface WLSwipeViewController : WLShakeViewController

- (id)initWithItems:(NSArray*)items currentItem:(id)item;

- (void)setItems:(NSArray*)items currentItem:(id)item;

- (UIView*)swipeView;

- (void)didSwipeLeft;
- (void)didSwipeRight;

- (void)willShowItem:(id)item;
- (void)willSelectItem:(id)item;

@property (strong, nonatomic) id item;
@property (strong, nonatomic) NSArray* items;

- (void)setSelectionBlock:(WLSwipeSelectionBlock)selectionBlock;

@end
