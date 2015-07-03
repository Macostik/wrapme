//
//  SegmentedControl.h
//  ProjectTemplate
//
//  Created by Sergey Maximenko on 10.08.12.
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

@property (nonatomic) BOOL selectionOnTouchUp;

- (void)deselect;

- (void)setEnabled:(BOOL)enabled segment:(NSInteger)segment;

- (UIControl*)controlForSegment:(NSInteger)segment;

- (void)setSelectedControl:(UIControl*)control;

@end
