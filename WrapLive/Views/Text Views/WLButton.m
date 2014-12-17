//
//  WLButton.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLButton.h"
#import "UIColor+CustomColors.h"
#import "UIView+AnimationHelper.h"

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
    if (!CGColorEqualToColor(backgroundColor.CGColor, self.backgroundColor.CGColor)) {
        [self setBackgroundColor:backgroundColor animated:self.animated];
    }
}

- (void)setNormalColor:(UIColor *)normalColor {
	_normalColor = normalColor;
	[self update];
}

- (UIColor *)defaultNormalColor {
	return self.backgroundColor;
}

- (UIColor *)defaultHighlightedColor {
	return [self defaultNormalColor];
}

- (UIColor *)defaultSelectedColor {
	return [self defaultNormalColor];
}

- (UIColor *)defaultDisabledColor {
	return [self defaultNormalColor];
}

- (UIColor *)normalColor {
	if (!_normalColor) _normalColor = [self defaultNormalColor];
	return _normalColor;
}

- (void)setHighlightedColor:(UIColor *)highlightedColor {
	_highlightedColor = highlightedColor;
	[self update];
}

- (UIColor *)hignlightedColor {
	if (!_highlightedColor) _highlightedColor = [self defaultHighlightedColor];
	return _highlightedColor;
}

- (void)setSelectedColor:(UIColor *)selectedColor {
	_selectedColor = selectedColor;
	[self update];
}

- (UIColor *)selectedColor {
	if (!_selectedColor) _selectedColor = [self defaultSelectedColor];
	return _selectedColor;
}

- (void)setDisabledColor:(UIColor *)disabledColor {
	_disabledColor = disabledColor;
	[self update];
}

- (UIColor *)disabledColor {
	if (!_disabledColor) _disabledColor = [self defaultDisabledColor];
	return _disabledColor;
}

- (void)setLoading:(BOOL)loading {
    if (_loading != loading) {
        _loading = loading;
        UIView *accessoryView = self.accessoryView;
        if (loading) {
            accessoryView.hidden = YES;
            CGPoint center;
            if (accessoryView) {
                center = [self convertPoint:accessoryView.center fromView:accessoryView.superview];
            } else {
                CGSize size = self.bounds.size;
                center = CGPointMake(size.width - size.height/2, size.height/2);
            }
            UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            spinner.center = center;
            if (self.spinnerColor) {
                spinner.color = self.spinnerColor;
            } else {
                spinner.color = [self titleColorForState:UIControlStateNormal];
            }
            [self addSubview:spinner];
            [spinner startAnimating];
            self.spinner = spinner;
            self.userInteractionEnabled = NO;
        } else {
            accessoryView.hidden = NO;
            [self.spinner removeFromSuperview];
            self.userInteractionEnabled = YES;
        }
    }
}

#pragma mark - WLFontCustomizing

@synthesize preset = _preset;

- (void)setPreset:(NSString *)preset {
    _preset = preset;
    self.titleLabel.font = [self.titleLabel.font preferredFontWithPreset:preset];
    [[WLFontPresetter presetter] addReceiver:self];
}

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter *)presetter {
    self.titleLabel.font = [self.titleLabel.font preferredFontWithPreset:self.preset];
}

@end

@implementation WLSegmentButton

- (void)setHighlighted:(BOOL)highlighted { }

@end

@implementation WLPressButton

- (UIColor *)defaultHighlightedColor {
    return [[self normalColor] colorByAddingValue:0.1f];
}

@end
