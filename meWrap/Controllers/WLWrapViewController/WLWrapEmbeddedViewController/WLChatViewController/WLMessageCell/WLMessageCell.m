//
//  WLMessageCell.m
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMessageCell.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface WLMessageCell () <EntryNotifying>

@property (weak, nonatomic) IBOutlet ImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet EntryStatusIndicator *indicator;

@end

@implementation WLMessageCell

- (void)awakeFromNib {
	[super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    [[FlowerMenu sharedMenu] registerView:self constructor:^(FlowerMenu *menu) {
        [menu addCopyAction:^(Message *message) {
            if (message.text.nonempty) {
                [[UIPasteboard generalPasteboard] setValue:message.text forPasteboardType:(id)kUTTypeText];
            }
        }];
        menu.entry = weakSelf.entry;
    }];
    
    UIColor *color = self.textView.superview.backgroundColor;
    if (self.tailView) {
        self.tailView.image = [WLMessageCell tailImageWithColor:color size:self.tailView.size drawing:^(CGSize size) {
            UIBezierPath *path = [UIBezierPath bezierPath];
            if (self.tailView.x > self.textView.superview.x) {
                [[path move:0 :0] quadCurve:size.width :0 controlX:size.width/2 controlY:size.height/2];
                [[path quadCurve:0 :size.height controlX:size.width controlY:size.height] line:0 :0];
            } else {
                [[path move:size.width :0] quadCurve:0 :0 controlX:size.width/2 controlY:size.height/2];
                [[path quadCurve:size.width :size.height controlX:0 controlY:size.height] line:size.width :0];
            }
            [color setFill];
            [path fill];
        }];
    }
}

+ (UIImage*)tailImageWithColor:(UIColor*)color size:(CGSize)size drawing:(void (^) (CGSize size))drawing {
    static NSDictionary *tails = nil;
    UIImage *image = [tails objectForKey:color];
    if (!image) {
        image = [UIImage draw:size opaque:NO scale:[UIScreen mainScreen].scale drawing:drawing];
        if (tails) {
            NSMutableDictionary *_tails = [tails mutableCopy];
            [_tails setObject:image forKey:color];
            tails = [_tails copy];
        } else {
            tails = [NSDictionary dictionaryWithObject:image forKey:color];
        }
    }
    return image;
}

- (void)setup:(Message*)message {
    if (self.nameLabel) {
        self.avatarView.url = message.contributor.avatar.small;
        self.nameLabel.text = message.contributor.name;
    }
    self.timeLabel.text = [message.createdAt stringWithTimeStyle:NSDateFormatterShortStyle];
    self.textView.text = message.text;
    if (self.indicator) {
        [self.indicator updateStatusIndicator:message];
    }
    
    [[FlowerMenu sharedMenu] hide];
}

@end
