//
//  WLMessageCell.m
//  meWrap
//
//  Created by Ravenpod on 09.04.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLMessageCell.h"
#import "WLImageView.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface WLMessageCell () <EntryNotifying>

@property (weak, nonatomic) IBOutlet WLImageView *avatarView;
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
        if (self.tailView.x > self.textView.superview.x) {
            self.tailView.image = [WLMessageCell tailImageWithColor:color size:self.tailView.size drawing:^(CGSize size) {
                UIBezierPath *path = [UIBezierPath bezierPath];
                [path moveToPoint:CGPointZero];
                [path addQuadCurveToPoint:CGPointMake(size.width, 0) controlPoint:CGPointMake(size.width/2, size.height/2)];
                [path addQuadCurveToPoint:CGPointMake(0, size.height) controlPoint:CGPointMake(size.width, size.height)];
                [path addLineToPoint:CGPointZero];
                [color setFill];
                [path fill];
            }];
        } else {
            self.tailView.image = [WLMessageCell tailImageWithColor:color size:self.tailView.size drawing:^(CGSize size) {
                UIBezierPath *path = [UIBezierPath bezierPath];
                [path moveToPoint:CGPointMake(size.width, 0)];
                [path addQuadCurveToPoint:CGPointMake(0, 0) controlPoint:CGPointMake(size.width/2, size.height/2)];
                [path addQuadCurveToPoint:CGPointMake(size.width, size.height) controlPoint:CGPointMake(0, size.height)];
                [path addLineToPoint:CGPointMake(size.width, 0)];
                [color setFill];
                [path fill];
            }];
        }
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
        self.avatarView.url = message.contributor.picture.small;
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
