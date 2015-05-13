//
//  WLDownloadingView.m
//  WrapLive
//
//  Created by Yura Granchenko on 12/05/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLDownloadingView.h"
#import "NSObject+NibAdditions.h"
#import "WLProgressBar+WLContribution.h"
#import "WLCandy+Extended.h"
#import "WLToast.h"

@interface WLDownloadingView ()

@property (weak, nonatomic) IBOutlet WLProgressBar *progressBar;
@property (weak, nonatomic) WLCandy *candy;

@end

@implementation WLDownloadingView

+ (instancetype)downloadingView:(UIView *)view
                       forCandy:(WLCandy *)candy
                        success:(WLBlock)success
                        failure:(WLFailureBlock)failure {
    return  [[WLDownloadingView loadFromNib] downloadingView:view
                                                    forEntry:candy
                                                     success:success
                                                     failure:failure];
}

- (instancetype)downloadingView:(UIView *)view
                       forEntry:(WLCandy *)candy
                        success:(WLBlock)success
                        failure:(WLFailureBlock)failure {
    self.frame = view.frame;
    self.candy = candy;
    [view addSubview:self];
    [self setFullFlexible];
    
    __weak __typeof(self)weakSelf = self;
    self.alpha = 0.0f;
    [UIView animateWithDuration:0.5f
                          delay:0.0f
         usingSpringWithDamping:1
          initialSpringVelocity:1
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [weakSelf downloadEntry:success failureBlock:failure];
    }];
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIColor *color = [UIColor colorWithWhite:0 alpha:.8];
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillRect (ctx, rect);
}

- (IBAction)calcel:(id)sender {
    [self dissmis];
}

- (void)dissmis {
    __weak typeof(self)weakSelf = self;
    run_in_main_queue(^{
        [UIView animateWithDuration:0.5f
                              delay:0.0f
             usingSpringWithDamping:1
              initialSpringVelocity:1
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            weakSelf.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    });
}

- (void)downloadEntry:(WLBlock)success failureBlock:(WLFailureBlock)failure {
    __weak __typeof(self)weakSelf = self;
    id operation = [self.candy download:^{
        [weakSelf dissmis];
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        [weakSelf dissmis];
        if (failure) {
            failure(error);
        }
    }];
    [weakSelf.progressBar setOperation:operation];
}

@end
