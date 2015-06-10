//
//  WLLightSegmentControl.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/06/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLLightSegmentControl.h"

@interface WLLightSegmentControl ()

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *buttonContainer;
@property (weak, nonatomic) IBOutlet UIView *singalView;

@end

@implementation WLLightSegmentControl

- (void)awakeFromNib {
    [super awakeFromNib];
    self.singalView.backgroundColor = self.activeColor;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.singalView.hidden = !selected;
    [self.buttonContainer setValue:selected ? self.activeColor : self.inActiveColor forKey:@"textColor"];
}

@end
