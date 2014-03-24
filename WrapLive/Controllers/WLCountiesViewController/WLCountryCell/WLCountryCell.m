//
//  WLCountryCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 24.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCountryCell.h"
#import "WLCountry.h"

@interface WLCountryCell ()

@property (weak, nonatomic) IBOutlet UILabel *countryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkmarkView;

@end

@implementation WLCountryCell

- (void)setupItemData:(WLCountry*)country {
	self.countryNameLabel.text = country.name;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	self.checkmarkView.hidden = !selected;
}

@end
