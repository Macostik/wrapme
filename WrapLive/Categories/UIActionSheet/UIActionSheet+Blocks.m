//
//  UIActionSheet+Blocks.m
//  WrapLive
//
//  Created by Sergey Maximenko on 06.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIActionSheet+Blocks.h"
#import <objc/runtime.h>
#import "NSObject+AssociatedObjects.h"
#import "WLNavigationHelper.h"

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
	[actionSheet showInView:[UIWindow mainWindow]];
}

+ (void)showWithTitle:(NSString *)title destructive:(NSString*)destructive completion:(WLActionSheetCompletion)completion {
	[self showWithTitle:title cancel:WLLS(@"Cancel") destructive:destructive completion:completion];
}

+ (void)showWithTitle:(NSString *)title cancel:(NSString*)cancel destructive:(NSString*)destructive completion:(WLActionSheetCompletion)completion {
	[self showWithTitle:title cancel:cancel destructive:destructive buttons:nil completion:completion];
}

+ (void)showWithCondition:(NSString *)title completion:(WLActionSheetCompletion)completion {
	[self showWithTitle:title cancel:WLLS(@"No") destructive:WLLS(@"Yes") completion:completion];
}

- (WLActionSheetCompletion)completion {
	return [self associatedObjectForKey:"wl_alertview_completion"];
}

- (void)setCompletion:(WLActionSheetCompletion)completion {
	[self setAssociatedObject:completion forKey:"wl_alertview_completion"];
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
