//
//  UIActionSheet+Blocks.m
//  WrapLive
//
//  Created by Sergey Maximenko on 06.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIActionSheet+Blocks.h"
#import <objc/runtime.h>

@interface UIActionSheet () <UIActionSheetDelegate>

@property (strong, nonatomic) WLActionSheetCompletion completion;

@end

@implementation UIActionSheet (Blocks)

+ (void)showWithTitle:(NSString *)title cancel:(NSString*)cancel destructive:(NSString*)destructive buttons:(NSArray *)buttons completion:(WLActionSheetCompletion)completion {
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:title delegate:nil cancelButtonTitle:cancel destructiveButtonTitle:destructive otherButtonTitles:nil];
	for (NSString* button in buttons) {
		[actionSheet addButtonWithTitle:button];
	}
	actionSheet.delegate = actionSheet;
	actionSheet.completion = completion;
	[actionSheet showInView:[[UIApplication sharedApplication].windows firstObject]];
}

- (WLActionSheetCompletion)completion {
	return objc_getAssociatedObject(self, "wl_alertview_completion");
}

- (void)setCompletion:(WLActionSheetCompletion)completion {
	objc_setAssociatedObject(self, "wl_alertview_completion", completion, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != self.cancelButtonIndex) {
		WLActionSheetCompletion completion = self.completion;
		if (completion) {
			completion(buttonIndex);
		}
	}
}

@end
