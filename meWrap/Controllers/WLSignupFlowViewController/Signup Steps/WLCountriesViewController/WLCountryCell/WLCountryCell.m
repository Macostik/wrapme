//
//  WLCountryCell.m
//  meWrap
//
//  Created by Ravenpod on 24.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCountryCell.h"

@interface WLCountryCell ()

@property (weak, nonatomic) IBOutlet UILabel *countryNameLabel;

@end

@implementation WLCountryCell

- (void)setup:(Country*)country {
	self.countryNameLabel.text = country.name;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    self.backgroundColor = selected ? [UIColor colorWithWhite:0.9 alpha:1] : [UIColor whiteColor];
}

@end
