//
//  WLTypingView.m
//  WrapLive
//
//  Created by Yura Granchenko on 10/15/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTypingViewCell.h"

@interface WLTypingViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *nameTextField;

@end

@implementation WLTypingViewCell

- (void)setNames:(NSString *)names {
    self.nameTextField.text = names;
    self.nameTextField.hidden = !names.nonempty;
}

@end
