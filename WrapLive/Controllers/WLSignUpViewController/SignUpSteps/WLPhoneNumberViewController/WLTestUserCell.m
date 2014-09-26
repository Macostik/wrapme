//
//  WLTestUserCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 9/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTestUserCell.h"
#import "NSString+Additions.h"
#import "WLAuthorization.h"

@interface WLTestUserCell ()

@property (weak, nonatomic) IBOutlet UILabel *phone;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *deviceUID;
@property (weak, nonatomic) IBOutlet UIView *active;

@end

@implementation WLTestUserCell

- (void)setAuthorization:(WLAuthorization *)authorization {
    _authorization = authorization;
    self.phone.text = [authorization fullPhoneNumber];
    self.email.text = [authorization email];
    self.deviceUID.text = [authorization deviceUID];
    self.active.hidden = !authorization.password.nonempty;
}

@end
