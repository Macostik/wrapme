//
//  WKInterfaceController+SimplifiedTextInput.m
//  moji
//
//  Created by Ravenpod on 6/16/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WKInterfaceController+SimplifiedTextInput.h"

@implementation WKInterfaceController (SimplifiedTextInput)

- (void)presentTextInputControllerWithSuggestionsFromFileNamed:(NSString *)fileName completion:(void (^)(NSString *result))completion {
    NSArray *presets = [NSArray plist:fileName];
    [self presentTextInputControllerWithSuggestions:presets allowedInputMode:WKTextInputModeAllowEmoji completion:^(NSArray *results) {
        for (NSString *result in results) {
            if ([result isKindOfClass:[NSString class]]) {
                if (completion) completion(result);
                break;
            }
        }
    }];
}

@end
