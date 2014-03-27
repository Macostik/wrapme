//
//  PGProgressBar.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 6/21/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "PGProgressBar.h"
#import "UIView+Shorthand.h"

@interface PGProgressBar ()

@property (strong, nonatomic) UIImageView *backgroundImageView;
@property (strong, nonatomic) UIImageView *progressImageView;

@property (nonatomic) CGFloat minimumProgressWidth;
@property (nonatomic) CGFloat maximumProgressWidth;

@end

@implementation PGProgressBar

- (void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.backgroundImageView.image = [UIImage imageNamed:@"picture_loading_progress_background"];
    
    CGRect progressFrame = self.bounds;
    progressFrame.origin.y = 1;
    progressFrame.size.height = progressFrame.size.height - 3;
    progressFrame.origin.x = 2;
    progressFrame.size.width = 0;
    self.minimumProgressWidth = 0;
    self.maximumProgressWidth = self.backgroundImageView.width - 4;
    self.progressImageView = [[UIImageView alloc] initWithFrame:progressFrame];
    self.progressImageView.image = [[UIImage imageNamed:@"picture_loading_progress_dynamic_segment"] stretchableImageWithLeftCapWidth:5
                                                                                                                         topCapHeight:5];
    [self addSubview:self.backgroundImageView];
    [self addSubview:self.progressImageView];
}

- (void)setProgress:(CGFloat)progress{
    if(_progress != progress){
        _progress = progress;
        [UIView beginAnimations:nil context:nil];
        self.progressImageView.width = progress *(self.maximumProgressWidth - self.minimumProgressWidth) + self.minimumProgressWidth;
        [UIView commitAnimations];
    }
}

@end
