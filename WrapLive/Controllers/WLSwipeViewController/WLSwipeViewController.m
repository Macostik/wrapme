//
//  WLSwipeViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 05.09.13.
//  Copyright (c) 2013 Andrey Ivanov. All rights reserved.
//

#import "WLSwipeViewController.h"
#import "UIView+QuatzCoreAnimations.h"
#import "NSOrderedSet+Additions.h"

@interface WLSwipeViewController ()

@property (copy, nonatomic) WLSwipeSelectionBlock selectionBlock;

@end

@implementation WLSwipeViewController

- (id)initWithItems:(NSOrderedSet *)items currentItem:(id)item {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        [self setItems:items currentItem:item];
    }
    return self;
}

- (NSMutableOrderedSet *)items {
    if (!_items) {
        _items = [NSMutableOrderedSet orderedSet];
    }
    return _items;
}

- (void)setItems:(NSOrderedSet *)items currentItem:(id)item {
	self.items = [NSMutableOrderedSet orderedSetWithOrderedSet:items];
	_item = item;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self configureSwipes];
    [self willShowItem:_item];
}

- (void)configureSwipes {
	UIView* swipeView = [self swipeView];
    UISwipeGestureRecognizer* leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipe:)];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [swipeView addGestureRecognizer:leftSwipeRecognizer];
    UISwipeGestureRecognizer* rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipe:)];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [swipeView addGestureRecognizer:rightSwipeRecognizer];
}

- (UIView *)swipeView {
    return self.view;
}

- (void)setItem:(id)item {
    _item = item;
    [self willShowItem:item];
}

#pragma mark - Abstract Methods

- (void)willShowItem:(id)item {
    
}

- (void)willSelectItem:(id)item {
    if (self.selectionBlock) {
        self.selectionBlock(item);
    }
}

- (void)didSwipeLeft:(NSUInteger)currentIndex {
	NSUInteger index = currentIndex + 1;
    if ([self.items containsIndex:index]) {
        id item = [self.items objectAtIndex:index];
        if ([self shouldSwipeToItem:item]) {
            [[self swipeView] leftPush];
            self.item = item;
        } else {
            [self didSwipeLeft:index];
        }
    }
}

- (void)didSwipeRight:(NSUInteger)currentIndex {
    NSUInteger index = currentIndex - 1;
    if ([self.items containsIndex:index]) {
        id item = [self.items objectAtIndex:index];
        if ([self shouldSwipeToItem:item]) {
            [[self swipeView] rightPush];
            self.item = item;
        } else {
            [self didSwipeRight:index];
        }
    }
}

- (BOOL)shouldSwipeToItem:(id)item {
    return YES;
}

- (NSUInteger)currentIndex {
	NSUInteger index = [self.items indexOfObject:self.item];
    if (index == NSNotFound) {
        index = [self repairedCurrentIndex];
    }
	return index;
}

- (NSUInteger)repairedCurrentIndex {
	return NSNotFound;
}

#pragma mark - User Actions

- (void)leftSwipe:(UISwipeGestureRecognizer*)recognizer {
    [self didSwipeLeft:[self currentIndex]];
}

- (void)rightSwipe:(UISwipeGestureRecognizer*)recognizer {
    [self didSwipeRight:[self currentIndex]];
}

- (IBAction)done:(UIButton *)sender {
    [self willSelectItem:self.item];
}

@end
