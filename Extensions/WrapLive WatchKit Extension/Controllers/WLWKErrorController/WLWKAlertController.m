//
//  WLWKErrorController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKAlertController.h"

@interface WLWKAlertController ()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel* errorLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *iconView;

@end

@implementation WLWKAlertController

- (void)awakeWithContext:(id)message {
    [super awakeWithContext:message];
    if ([message isKindOfClass:[NSError class]]) {
        [self.iconView setHidden:NO];
        [self.errorLabel setText:[message localizedDescription]];
    } else if ([message isKindOfClass:[NSString class]]) {
        [self.iconView setHidden:YES];
        [self.errorLabel setText:message];
    }
    __weak typeof(self)weakSelf = self;
    run_after(3, ^{
        [weakSelf popController];
    });
    // Configure interface objects here.
}

@end



