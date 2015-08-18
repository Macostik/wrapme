//
//  StreamItem.m
//  Moji
//
//  Created by Sergey Maximenko on 8/18/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamItem.h"
#import "StreamReusableView.h"

@implementation StreamItem

@synthesize selected = _selected;

- (void)setVisible:(BOOL)visible {
    if (_visible != visible) {
        if (visible) {
            [self.delegate streamItemWillBecomeVisible:self];
        } else {
            [self.delegate streamItemWillBecomeInvisible:self];
        }
        _visible = visible;
    }
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    if (_view) {
        _view.selected = selected;
    }
}

- (void)setView:(StreamReusableView *)view {
    _view = view;
    view.selected = self.selected;
}

@end
