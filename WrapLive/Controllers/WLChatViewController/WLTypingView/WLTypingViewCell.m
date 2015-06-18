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
@property (weak, nonatomic) IBOutlet WLImageView *avatarView;

@end

@implementation WLTypingViewCell

- (void)setNames:(NSString *)names {
    self.nameTextField.text = names;
    self.nameTextField.hidden = !names.nonempty;
}

- (void)setAvatar:(NSString *)url {
    if (url.isValidUrl) {
         self.avatarView.url = url;
    } else {
        [self.avatarView setImage:[UIImage imageNamed:url]];
    }
}

@end
