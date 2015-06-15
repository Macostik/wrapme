//
//  WLWKErrorController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/15/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKErrorController.h"

@interface WLWKErrorController ()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel* errorLabel;

@end

@implementation WLWKErrorController

- (void)awakeWithContext:(NSError*)error {
    [super awakeWithContext:error];
    [self.errorLabel setText:error.localizedDescription];
    __weak typeof(self)weakSelf = self;
    run_after(3, ^{
        [weakSelf popController];
    });
    // Configure interface objects here.
}

@end



