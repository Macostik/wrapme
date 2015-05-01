//
//  MFMailComposeViewController+Additions.m
//  WrapLive
//
//  Created by Oleg Vyshnivetsky on 5/29/14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "MFMailComposeViewController+Additions.h"
#import "WLCandy.h"
#import "WLWrap.h"
#import "WLToast.h"
#import "WLNavigationHelper.h"

@interface MFMailComposeViewController () <MFMailComposeViewControllerDelegate>

@end

@implementation MFMailComposeViewController (Additions)

+ (void)messageWithCandy:(WLCandy *)candy {
    if ([MFMailComposeViewController canSendMail]) {
        NSString *emailTitle = @"Reporting inappropriate content on wrapLive";
        // Email Content
        NSString *messageBody = [NSString stringWithFormat:@"I'd like to report the following item as inappropriate content:\nImage URL - %@,\nWrap ID - %@,\nCandy ID - %@", candy.picture.medium, candy.wrap.identifier, candy.identifier];
        // To address
        NSArray *toRecipents = [NSArray arrayWithObject:@"help@ravenpod.com"];
        
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = mc;
        [mc setSubject:emailTitle];
        [mc setMessageBody:messageBody isHTML:NO];
        [mc setToRecipients:toRecipents];
        [[UINavigationController topViewController] presentViewController:mc animated:YES completion:NULL];
    } else {
        [WLToast showWithMessage:@"Please set up Email account on your device."];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	if (result == MFMailComposeResultSent) {
		WLToastAppearance* appearance = [WLToastAppearance appearance];
		appearance.shouldShowIcon = NO;
		[WLToast showWithMessage:@"Mail sent.\nThank you for your help!" appearance:appearance];
	}
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
