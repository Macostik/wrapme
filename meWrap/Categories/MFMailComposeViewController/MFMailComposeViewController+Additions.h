//
//  MFMailComposeViewController+Additions.h
//  meWrap
//
//  Created by Ravenpod on 5/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@class WLCandy;
@class WLWrap;

@interface MFMailComposeViewController (Additions)

+ (void)messageWithCandy:(WLCandy *)candy;

@end
