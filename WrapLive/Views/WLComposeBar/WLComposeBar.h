//
//  WLComposeBar.h
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLComposeBar;

@protocol WLComposeBarDelegate <NSObject>

@optional;
- (void)composeBar:(WLComposeBar*)composeBar didFinishWithText:(NSString*)text;
- (void)composeBarDidChangeHeight:(WLComposeBar*)composeBar;
- (void)composeBarDidChangeText:(WLComposeBar*)composeBar;
- (NSUInteger)composeBarCharactersLimit:(WLComposeBar*)composeBar;
- (void)composeBarDidBeginEditing:(WLComposeBar*)composeBar;
- (void)composeBarDidEndEditing:(WLComposeBar*)composeBar;
- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar*)composeBar;

@end

@interface WLComposeBar : UIControl

@property (nonatomic, weak) IBOutlet id delegate;

@property (strong, nonatomic) NSString* text;

@property (strong, nonatomic) NSString* placeholder;

@property (nonatomic) BOOL doneButtonHidden;

@property (nonatomic) BOOL showsDoneButtonOnEditing;

- (void)setDoneButtonHidden:(BOOL)hidden animated:(BOOL)animated;

@end