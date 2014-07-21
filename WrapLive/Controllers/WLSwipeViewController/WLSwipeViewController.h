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

- (id)initWithItems:(NSOrderedSet*)items currentItem:(id)item;

- (void)setItems:(NSOrderedSet*)items currentItem:(id)item;

- (UIView*)swipeView;

- (void)didSwipeLeft:(NSUInteger)currentIndex;
- (void)didSwipeRight:(NSUInteger)currentIndex;

- (BOOL)shouldSwipeToItem:(id)item;

- (void)willShowItem:(id)item;
- (void)willSelectItem:(id)item;

- (NSUInteger)repairedCurrentIndex;

@property (strong, nonatomic) id item;
@property (strong, nonatomic) NSMutableOrderedSet* items;

- (void)setSelectionBlock:(WLSwipeSelectionBlock)selectionBlock;

@end
