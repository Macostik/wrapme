//
//  WLButton.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLButton.h"

@interface WLButton ()

@property (weak, nonatomic) UIActivityIndicatorView *spinner;

@end

@implementation WLButton

@synthesize normalColor = _normalColor;
@synthesize highlightedColor = _highlightedColor;
@synthesize selectedColor = _selectedColor;
@synthesize disabledColor = _disabledColor;

- (void)awakeFromNib {
    [super awakeFromNib];
    [self update];
}

- (void)setHighlighted:(BOOL)highlighted {
	[super setHighlighted:highlighted];
	[self update];
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	[self update];
}

- (void)setEnabled:(BOOL)enabled {
	[super setEnabled:enabled];
	[self update];
}

- (void)update {
    UIColor *backgroundColor = nil;
    if (self.enabled) {
        if (self.highlighted) {
            backgroundColor = self.hignlightedColor;
        } else {
            backgroundColor = self.selected ? self.selectedColor : self.normalColor;
        }
    } else {
        backgroundColor = self.disabledColor;
    }
	self.backgroundColor = backgroundColor;
}

- (void)setNormalColor:(UIColor *)normalColor {
	_normalColor = normalColor;
	[self update];
}

- (UIColor *)normalColor {
	if (!_normalColor) _normalColor = [UIColor clearColor];
	return _normalColor;
}

- (void)setHighlightedColor:(UIColor *)highlightedColor {
	_highlightedColor = highlightedColor;
	[self update];
}

- (UIColor *)hignlightedColor {
	if (!_highlightedColor) _highlightedColor = self.normalColor;
	return _highlightedColor;
}

- (void)setSelectedColor:(UIColor *)selectedColor {
	_selectedColor = selectedColor;
	[self update];
}

- (UIColor *)selectedColor {
	if (!_selectedColor) _selectedColor = self.normalColor;
	return _selectedColor;
}

- (void)setDisabledColor:(UIColor *)disabledColor {
	_disabledColor = disabledColor;
	[self update];
}

- (UIColor *)disabledColor {
	if (!_disabledColor) _disabledColor = self.normalColor;
	return _disabledColor;
}

- (void)setLoading:(BOOL)loading {
    if (_loading != loading) {
        _loading = loading;
        if (loading) {
            UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            spinner.center = CGPointMake(self.bounds.size.width - self.bounds.size.height/2, self.bounds.size.height/2);
            [self addSubview:spinner];
            [spinner startAnimating];
            self.spinner = spinner;
            self.userInteractionEnabled = NO;
        } else {
            [self.spinner removeFromSuperview];
            self.userInteractionEnabled = YES;
        }
    }
}

@end

@implementation WLSegmentButton

- (void)setHighlighted:(BOOL)highlighted { }

@end
