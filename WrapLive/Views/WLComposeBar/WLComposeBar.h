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

- (void)composeBar:(WLComposeBar*)composeBar didFinishWithText:(NSString*)text;
- (void)composeBarDidReturn:(WLComposeBar*)composeBar;

@optional;

- (NSUInteger)composeBarCharactersLimit:(WLComposeBar*)composeBar;
- (void)composeBarDidBeginEditing:(WLComposeBar*)composeBar;
- (void)composeBarDidEndEditing:(WLComposeBar*)composeBar;
- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar*)composeBar;

@end

@interface WLComposeBar : UIView

@property (nonatomic, weak) IBOutlet id <WLComposeBarDelegate> delegate;

@property (strong, nonatomic) NSString* text;

@property (strong, nonatomic) NSString* placeHolder;

@end
