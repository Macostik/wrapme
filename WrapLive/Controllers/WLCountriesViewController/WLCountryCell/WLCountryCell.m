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

@end

@implementation WLCountryCell

- (void)setup:(WLCountry*)country {
	self.countryNameLabel.text = country.name;
}

@end
