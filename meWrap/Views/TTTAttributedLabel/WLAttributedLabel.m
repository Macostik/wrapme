//
//  WLAttributedLabel.m
//  meWrap
//
//  Created by Sergey Maximenko on 9/21/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLAttributedLabel.h"
#import <SafariServices/SafariServices.h>

@interface WLAttributedLabel () <TTTAttributedLabelDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) void (^actionSheetCallback) (NSUInteger buttonIndex);

@end

@implementation WLAttributedLabel

- (void)awakeFromNib {
    [super awakeFromNib];
    self.delegate = self;
    self.enabledTextCheckingTypes = NSTextCheckingTypeLink;
//    self.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
}

// MARK: - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didLongPressLinkWithURL:(NSURL *)url atPoint:(CGPoint)point {
    [[[UIActionSheet alloc] initWithTitle:url.absoluteString delegate:self cancelButtonTitle:WLLS(@"cancel") destructiveButtonTitle:nil otherButtonTitles:WLLS(@"url_open_in_safari"), WLLS(@"url_add_to_reading_list"), WLLS(@"copy"), nil] showInView:self.window];
    [self setActionSheetCallback:^(NSUInteger buttonIndex) {
        if (buttonIndex == 0) {
            [[UIApplication sharedApplication] openURL:url];
        } else if (buttonIndex == 1) {
            [[SSReadingList defaultReadingList] addReadingListItemWithURL:url title:nil previewText:nil error:NULL];
        } else {
            [[UIPasteboard generalPasteboard] setValue:url.absoluteString forPasteboardType:(id)kUTTypeText];
        }
    }];
}

// MARK: - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (self.actionSheetCallback) self.actionSheetCallback(buttonIndex);
    self.actionSheetCallback = nil;
}

@end
