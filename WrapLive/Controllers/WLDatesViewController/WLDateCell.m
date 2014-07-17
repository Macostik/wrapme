//
//  WLDateCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 7/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLDateCell.h"
#import "WLGroupedSet.h"
#import "WLCandy.h"
#import "NSDate+Formatting.h"
#import "WLImageFetcher.h"

@interface WLDateCell ()

@property (weak, nonatomic) IBOutlet UIImageView *pictureView;
@property (weak, nonatomic) IBOutlet UILabel *dayLabel;
@property (weak, nonatomic) IBOutlet UILabel *monthLabel;

@end

@implementation WLDateCell

- (void)setupItemData:(WLGroup*)group {
    WLCandy* candy = [group.entries selectObject:^BOOL(id item) {
        return [item isImage];
    }];
    self.pictureView.url = [candy isMessage] ? candy.contributor.picture.medium : candy.picture.medium;
    self.dayLabel.text = [group.date stringWithFormat:@"d"];
    self.monthLabel.text = [group.date stringWithFormat:@"MM"];
}

- (IBAction)select:(id)sender {
    [self.delegate dateCell:self didSelectGroup:self.item];
}

@end
