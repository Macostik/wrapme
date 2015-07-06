//
//  PICSegmentedControl.m
//  Riot
//
//  Created by Sergey Maximenko on 10.08.12.
//
//

#import "SegmentedControl.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+QuatzCoreAnimations.h"

@interface SegmentedControl ()

@property (nonatomic, strong) NSArray* controls;
@property (nonatomic, weak) IBOutlet UIView* selectionView;

@end

@implementation SegmentedControl {
	BOOL _horizontal;
}

- (NSArray*)controls {
	if (!_controls) {
		_controls = [self.subviews map:^id(UIView* view) {
			view.exclusiveTouch = YES;
			return [view isKindOfClass:[UIControl class]] ? view : nil;
		}];
	}
	return _controls;
}

- (void)deselect {
	self.selectedSegment = NSNotFound;
}

- (void)setup {
	NSArray* controls = self.controls;
	
	CGFloat dx = 0.0f;
	CGFloat dy = 0.0f;
	
	UIControl* previousControl = nil;
	
	for (UIControl* control in controls) {
		[control addTarget:self action:@selector(selectSegmentTap:) forControlEvents:UIControlEventTouchDown];
		[control addTarget:self action:@selector(selectSegmentTouchUp:) forControlEvents:UIControlEventTouchUpInside];
		
		dx += (control.frame.origin.x - previousControl.frame.origin.x);
		dy += (control.frame.origin.y - previousControl.frame.origin.y);
		
		previousControl = control;
	}
	
	_horizontal = (dx > dy);
	
	self.selectedSegment = 0;
}

- (void)setSelectedSegment:(NSInteger)selectedSegment {
	[self setSelectedControl:[self controlForSegment:selectedSegment]];
}

- (void)setSelectedControl:(UIControl*)control {
	
	[self.selectionView fadeWithDuration:0.2 delegate:nil];
	
	self.selectionView.hidden = YES;
	
	for (UIControl* _control in self.controls) {
		_control.selected = (_control == control);
		
		if (self.selectionView != nil && _control.selected) {
			
			self.selectionView.hidden = NO;
			
			CGRect frame = self.selectionView.frame;
			
			if (_horizontal) {
				frame.origin.x = (CGRectGetMidX(_control.frame) - frame.size.width/2.0f);
			} else {
				frame.origin.y = (CGRectGetMidY(_control.frame) - frame.size.height/2.0f);
			}
			
			self.selectionView.frame = frame;
		}
	}
}

- (NSInteger)selectedSegment {
	return [self.controls indexOfObjectPassingTest:^BOOL(UIControl* control, NSUInteger idx, BOOL *stop) {
		return control.selected;
	}];
}

- (void)awakeFromNib {
	[self setup];
}

- (void)handleTap:(UIControl*)sender {
	NSArray* controls = self.controls;
	NSUInteger index = [controls indexOfObject:sender];
	
	if (index != NSNotFound) {

		if ([self.delegate respondsToSelector:@selector(segmentedControl:shouldSelectSegment:)]) {
			if (![self.delegate segmentedControl:self shouldSelectSegment:index]) {
				return;
			}
		}
		
		[self setSelectedControl:sender];
		
		if ([self.delegate respondsToSelector:@selector(segmentedControl:didSelectSegment:)]) {
			[self.delegate segmentedControl:self didSelectSegment:self.selectedSegment];
		}
		
		[self sendActionsForControlEvents:UIControlEventValueChanged];
	}
}

- (void)selectSegmentTap:(UIControl*)sender {
	if (!self.selectionOnTouchUp) {
		[self handleTap:sender];
	}
}

- (void)selectSegmentTouchUp:(UIControl*)sender {
	if (self.selectionOnTouchUp) {
		[self handleTap:sender];
	}
}

- (void)setEnabled:(BOOL)enabled segment:(NSInteger)segment {
	[self controlForSegment:segment].enabled = enabled;
}

- (UIControl *)controlForSegment:(NSInteger)segment {
	NSArray* controls = self.controls;
	if (segment >= 0 && segment < [controls count]) {
		return [controls objectAtIndex:segment];
	}
	return nil;
}

@end
