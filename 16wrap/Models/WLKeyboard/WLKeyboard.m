//
//  WLKeyboard.m
//  moji
//
//  Created by Ravenpod on 24.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLKeyboard.h"
#import "UIView+GestureRecognizing.h"
#import "WLNavigationHelper.h"
#import "UIView+AnimationHelper.h"
#import "UIDevice+SystemVersion.h"

@interface WLKeyboard ()

@end

@implementation WLKeyboard

+ (instancetype)keyboard {
    static id instance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = [[self alloc] init];
	});
    return instance;
}

- (void)setup {
    [super setup];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.height = keyboardSize.height;
    self.duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    self.isShow = self.height != 0;
	[self broadcast:@selector(keyboardWillShow:)];
}

- (void)keyboardDidShow:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    CGSize keyboardSize = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    self.height = keyboardSize.height;
    self.duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	[self broadcast:@selector(keyboardDidShow:)];
	__weak UIWindow* window = [UIWindow mainWindow];
    [UITapGestureRecognizer recognizerWithView:window identifier:@"WLKeyboardTapGestureRecognizer" block:^(UIGestureRecognizer *recognizer) {
        [window endEditing:YES];
    }];
}

- (void)keyboardWillHide:(NSNotification*)notification {
    self.height = 0;
    NSDictionary *userInfo = [notification userInfo];
    self.duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    self.curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    self.isShow = self.height != 0;
	[self broadcast:@selector(keyboardWillHide:)];
}

- (void)keyboardDidHide:(NSNotification*)notification {
    self.height = 0;
    self.duration = 0;
    self.curve = 0;
	[self broadcast:@selector(keyboardDidHide:)];
    [[UIWindow mainWindow] removeGestureRecognizerWithIdentifier:@"WLKeyboardTapGestureRecognizer"];
}

- (void)performAnimation:(WLBlock)animation {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:self.duration];
    [UIView setAnimationCurve:self.curve];
    if (animation) animation();
    [UIView commitAnimations];
}

@end
