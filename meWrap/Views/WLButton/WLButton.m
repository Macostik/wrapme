//
//  WLButton.m
//  meWrap
//
//  Created by Ravenpod on 8/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLButton.h"

@interface WLButton ()

@property (weak, nonatomic) UIActivityIndicatorView *spinner;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *highlightings;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *selectings;

@end

@implementation WLButton

@synthesize normalColor = _normalColor;
@synthesize highlightedColor = _highlightedColor;
@synthesize selectedColor = _selectedColor;
@synthesize disabledColor = _disabledColor;
@synthesize touchArea = _touchArea;

- (void)awakeFromNib {
    [super awakeFromNib];
    [self update];
}

- (void)setLocalize:(BOOL)localize {
    _localize = localize;
    if (localize) {
        NSString *text = self.titleLabel.text;
        if (text.nonempty) {
            [super setTitle:text.ls forState:UIControlStateNormal];
        }
    }
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    if (self.localize) {
        [super setTitle:title.ls forState:state];
    } else {
        [super setTitle:title forState:state];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self update];
    for (UIControl *highlighting in self.highlightings) {
        if ([highlighting respondsToSelector:@selector(setHighlighted:)]) {
            highlighting.highlighted = highlighted;
        }
    }
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	[self update];
    for (UIControl *selecting in self.selectings) {
        if ([selecting respondsToSelector:@selector(setSelected:)]) {
            selecting.selected = selected;
        } else if ([selecting respondsToSelector:@selector(setHighlighted:)]) {
            selecting.highlighted = selected;
        }
    }
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
            UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            if (self.spinnerColor) {
                spinner.color = self.spinnerColor;
            } else {
                spinner.color = [self titleColorForState:UIControlStateNormal];
            }
            CGPoint center;
            UIView *spinnerSuperview = self;
            if (accessoryView) {
                center = [self convertPoint:accessoryView.center fromView:accessoryView.superview];
            } else {
                CGFloat contentWidth = [self sizeThatFits:self.size].width;
                if ((self.width - contentWidth) < spinner.width) {
                    spinnerSuperview = self.superview;
                    center = self.center;
                    self.alpha = 0;
                } else {
                    CGSize size = self.bounds.size;
                    center = CGPointMake(size.width - size.height/2, size.height/2);
                }
            }
            spinner.center = center;
            [spinnerSuperview addSubview:spinner];
            [spinner startAnimating];
            self.spinner = spinner;
            self.userInteractionEnabled = NO;
        } else {
            accessoryView.hidden = NO;
            if (self.spinner.superview != self) {
                self.alpha = 1;
            }
            [self.spinner removeFromSuperview];
            self.userInteractionEnabled = YES;
        }
    }
}

- (void)setPreset:(NSString *)preset {
    _preset = preset;
    self.titleLabel.font = [self.titleLabel.font fontWithPreset:preset];
    [[FontPresetter defaultPresetter] addReceiver:self];
}

static CGFloat minTouchSize = 44;
- (CGSize)touchArea {
    if (CGSizeEqualToSize(_touchArea, CGSizeZero)) _touchArea = CGSizeMake(minTouchSize, minTouchSize);
    return _touchArea;
}

- (void)presetterDidChangeContentSizeCategory:(FontPresetter *)presetter {
    self.titleLabel.font = [self.titleLabel.font fontWithPreset:self.preset];
}

- (CGSize)intrinsicContentSize {
    CGSize intrinsicSize = super.intrinsicContentSize;
    return CGSizeMake(intrinsicSize.width + self.insets.width, intrinsicSize.height + self.insets.height);
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect rect = self.bounds;
    if (rect.size.width < self.touchArea.width) {
        CGFloat dx = self.touchArea.width - rect.size.width;
        rect.size.width += dx;
        rect.origin.x -= dx/2;
    }
    if (rect.size.height < self.touchArea.height) {
        CGFloat dy = self.touchArea.height - rect.size.height;
        rect.size.height += dy;
        rect.origin.y -= dy/2;
    }
    return CGRectContainsPoint(rect, point);
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
