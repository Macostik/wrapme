//
//  WLWKCandyRow.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCandyEventRow.h"
#import "WLWKImageCache.h"
#import "WLUser+Extended.h"
#import "WLCandy+Extended.h"
#import "WLWrap+Extended.h"
#import "NSDate+Additions.h"

@implementation WLWKCandyEventRow

- (void)setEntry:(WLCandy *)entry {
    [self.group setHeight:[WKInterfaceDevice currentDevice].screenBounds.size.width];
    NSString *header = [NSString stringWithFormat:@"%@ in \"%@\"\n", entry.contributor.name, entry.wrap.name];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:header attributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Light" size:10], NSForegroundColorAttributeName:[UIColor orangeColor]}];
    NSString *time = [entry.updatedAt timeAgoStringAtAMPM];
    NSMutableAttributedString *body = [[NSMutableAttributedString alloc] initWithString:time attributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Light" size:10],NSForegroundColorAttributeName:[UIColor whiteColor]}];
    [text appendAttributedString:body];
    [self.text setAttributedText:text];
    
    __weak typeof(self)weakSelf = self;
    [WLWKImageCache imageWithURL:entry.picture.small completion:^(UIImage *image) {
        [weakSelf.group setBackgroundImage:image];
    }];
}

@end
