//
//  CountryCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
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
    self.backgroundColor = selected ? [UIColor gray:230] : [UIColor whiteColor];
}

@end
