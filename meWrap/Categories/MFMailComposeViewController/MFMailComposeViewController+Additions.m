//
//  MFMailComposeViewController+Additions.m
//  meWrap
//
//  Created by Ravenpod on 5/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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
        NSString *emailTitle = @"Reporting inappropriate content on meWrap";
        // Email Content
        NSString *messageBody = [NSString stringWithFormat:@"I'd like to report the following item as inappropriate content:\nImage URL - %@,\nmeWrapp ID - %@,\nCandy ID - %@", candy.picture.original, candy.wrap.identifier, candy.identifier];
        // To address
        NSArray *toRecipents = [NSArray arrayWithObject:@"help@ravenpod.com"];
        
        MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
        mc.mailComposeDelegate = mc;
        [mc setSubject:emailTitle];
        [mc setMessageBody:messageBody isHTML:NO];
        [mc setToRecipients:toRecipents];
        [[UINavigationController topViewController] presentViewController:mc animated:YES completion:NULL];
    } else {
        [WLToast showWithMessage:WLLS(@"email_account_setup")];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	if (result == MFMailComposeResultSent) {
		[WLToast showWithMessage:WLLS(@"mail_sent")];
	}
	[self dismissViewControllerAnimated:YES completion:NULL];
}

@end
