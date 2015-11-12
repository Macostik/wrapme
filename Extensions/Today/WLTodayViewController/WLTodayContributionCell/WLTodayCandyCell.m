//
//  WLTodayCandyCell.m
//  meWrap
//
//  Created by Ravenpod on 3/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLTodayCandyCell.h"

@interface WLTodayCandyCell ()

@end

@implementation WLTodayCandyCell

- (void)setContribution:(Candy *)candy {
    [super setContribution:candy];
    self.pictureView.url = candy.picture.small;
    self.wrapNameLabel.text = candy.wrap.name;
    self.descriptionLabel.text = [NSString stringWithFormat:@"%@ posted a new photo", candy.contributor.name];
}

@end
