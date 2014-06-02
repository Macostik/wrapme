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

@property (nonatomic, weak) IBOutlet id <SegmentedControlDelegate> delegate;

@property (nonatomic) NSInteger selectedSegment;

@property (nonatomic) BOOL selectionOnTouchUp;

- (void)deselect;

- (void)setEnabled:(BOOL)enabled segment:(NSInteger)segment;

- (UIControl*)controlForSegment:(NSInteger)segment;

@end

@interface SegmentButton : UIButton

@property (strong, nonatomic) UIColor *selectedColor;
@property (strong, nonatomic) UIColor *normalColor;

@end
