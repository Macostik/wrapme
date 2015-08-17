//
//  SegmentedControl.h
//  ProjectTemplate
//
//  Created by Ravenpod on 10.08.12.
//
//

#import <UIKit/UIKit.h>

@class SegmentedControl;

@protocol SegmentedControlDelegate <NSObject>

@optional
- (void)segmentedControl:(SegmentedControl*)control didSelectSegment:(NSInteger)segment;
- (BOOL)segmentedControl:(SegmentedControl*)control shouldSelectSegment:(NSInteger)segment;

@end

@interface SegmentedControl : UIControl

@property (nonatomic, readonly)  NSArray* controls;

@property (nonatomic, weak) IBOutlet id <SegmentedControlDelegate> delegate;

@property (nonatomic) NSInteger selectedSegment;

@property (nonatomic) UIControlEvents selectionEvent;

- (void)deselect;

- (void)setEnabled:(BOOL)enabled segment:(NSInteger)segment;

- (UIControl*)controlForSegment:(NSInteger)segment;

@end
