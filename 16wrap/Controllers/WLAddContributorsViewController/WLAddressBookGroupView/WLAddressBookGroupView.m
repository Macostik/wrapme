//
//  WLAddressBookGroupView.m
//  moji
//
//  Created by Ravenpod on 2/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLAddressBookGroupView.h"
#import "WLArrangedAddressBookGroup.h"

@interface WLAddressBookGroupView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation WLAddressBookGroupView

- (void)setGroup:(WLArrangedAddressBookGroup *)group {
    _group = group;
    self.titleLabel.text = group.title;
}

@end
