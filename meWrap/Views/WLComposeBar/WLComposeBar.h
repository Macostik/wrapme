//
//  WLComposeBar.h
//  meWrap
//
//  Created by Ravenpod on 31.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
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

@property (weak, nonatomic) IBOutlet LayoutPrioritizer *trailingPrioritizer;

@property (strong, nonatomic) NSString* text;

@property (strong, nonatomic) NSString* placeholder;

@property (nonatomic) BOOL doneButtonHidden;

@end