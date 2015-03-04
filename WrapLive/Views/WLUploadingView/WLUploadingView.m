//
//  WLUploadingView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 3/4/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadingView.h"
#import "WLUploadingQueue.h"
#import "WLNetwork.h"
#import "UIView+QuatzCoreAnimations.h"
#import "UIColor+CustomColors.h"

@interface WLUploadingView () <WLUploadingQueueReceiver, WLNetworkReceiver>

@property (weak, nonatomic) IBOutlet UILabel* countLabel;
@property (weak, nonatomic) IBOutlet UIButton* arrowIcon;

@property (strong, nonatomic) CABasicAnimation* animation;

@property (nonatomic) BOOL animating;

@end

@implementation WLUploadingView

- (void)awakeFromNib {
    [super awakeFromNib];
    [[WLNetwork network] addReceiver:self];
}

- (void)setQueue:(WLUploadingQueue *)queue {
    _queue = queue;
    [queue addReceiver:self];
}

#pragma mark - WLUploadingQueueReceiver

- (void)update {
    [self updateWithQueue:self.queue];
}

- (void)updateWithQueue:(WLUploadingQueue*)queue {
    [self fade];
    self.hidden = queue.isEmpty;
    if (!self.hidden) {
        self.countLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)queue.count];
        BOOL networkReachable = [WLNetwork network].reachable;
        self.backgroundColor = [(networkReachable ? [UIColor WL_orangeColor] : [UIColor WL_grayLight]) colorWithAlphaComponent:0.8f];
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}



- (void)startAnimating {
    if (self.hidden || ![WLNetwork network].reachable) {
        [self stopAnimating];
        return;
    }
    if (self.animating) return;
    self.animating = YES;
    [self.arrowIcon.layer addAnimation:self.animation forKey:@"uploading"];
    
}

- (CABasicAnimation *)animation {
    if (!_animation) {
        _animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        _animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, 5, 0)];
        _animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, -5, 0)];
        _animation.duration = 1.0f;
        _animation.repeatCount = FLT_MAX;
    }
    return _animation;
}

- (void)stopAnimating {
    self.animating = NO;
    [self.arrowIcon.layer removeAnimationForKey:@"uploading"];
}

- (void)uploadingQueueDidStart:(WLUploadingQueue *)queue {
    [self updateWithQueue:queue];
}

- (void)uploadingQueueDidChange:(WLUploadingQueue *)queue {
    [self updateWithQueue:queue];
}

- (void)uploadingQueueDidStop:(WLUploadingQueue *)queue {
    [self updateWithQueue:queue];
}

#pragma mark - WLNetworkReceiver

- (void)networkDidChangeReachability:(WLNetwork *)network {
    [self update];
}

@end
