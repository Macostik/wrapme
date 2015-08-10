//
//  WKInterfaceController+SimplifiedTextInput.h
//  moji
//
//  Created by Ravenpod on 6/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface WKInterfaceController (SimplifiedTextInput)

- (void)presentTextInputControllerWithSuggestionsFromFileNamed:(NSString *)fileName completion:(void (^)(NSString *result))completion;

@end
