//
//  WLWKCommentRowType.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKCommentEventRow.h"
#import "WLComment+Extended.h"
#import "WLUser+Extended.h"
#import "WLCandy+Extended.h"
#import "WLWrap+Extended.h"
#import "NSDate+Additions.h"
#import "WKInterfaceImage+WLImageFetcher.h"

@implementation WLWKCommentEventRow

- (void)setEntry:(WLComment *)entry {
    NSString *header = [NSString stringWithFormat:@"%@ in \"%@\"\n", entry.contributor.name, entry.candy.wrap.name];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:header attributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Light" size:10], NSForegroundColorAttributeName:[UIColor orangeColor]}];
    NSString *time = [entry.updatedAt timeAgoStringAtAMPM];
    NSMutableAttributedString *body = [[NSMutableAttributedString alloc] initWithString:time attributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Light" size:10],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
    [text appendAttributedString:body];
    [self.text setAttributedText:text];
    
    self.icon.url = entry.picture.small;
    
    NSString *comment = [NSString stringWithFormat:@"\"%@\"", entry.text];
    [self.comment setAttributedText:[[NSAttributedString alloc] initWithString:comment attributes:@{NSFontAttributeName:[UIFont fontWithName:@"OpenSans-Light" size:12], NSForegroundColorAttributeName:[UIColor blackColor]}]];
}

@end
