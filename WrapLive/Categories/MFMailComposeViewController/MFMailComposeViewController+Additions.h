//
//  MFMailComposeViewController+Additions.h
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/29/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <MessageUI/MessageUI.h>

@class WLCandy;
@class WLWrap;

@interface MFMailComposeViewController (Additions)

+ (void)messageWithCandy:(WLCandy *)candy andWrap:(WLWrap *)wrap;

@end
