//
//  WLUploadingView.m
//  meWrap
//
//  Created by Ravenpod on 3/4/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLUploadingView.h"
#import "WLUploadingQueue.h"
#import "WLNetwork.h"

@interface WLUploadingView () <WLUploadingQueueReceiver, WLNetworkReceiver>

@property (weak, nonatomic) IBOutlet UILabel* countLabel;
@property (weak, nonatomic) IBOutlet UIButton* arrowIcon;

@property (strong, nonatomic) CABasicAnimation* animation;

@end

@implementation WLUploadingView

- (void)awakeFromNib {
    [super awakeFromNib];
    [[WLNetwork sharedNetwork] addReceiver:self];
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
    [self addAnimation:[CATransition transition:kCATransitionFade]];
    self.hidden = queue.isEmpty;
    if (!self.hidden) {
        self.countLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)queue.count];
        BOOL networkReachable = [WLNetwork sharedNetwork].reachable;
        self.backgroundColor = [(networkReachable ? Color.orange : Color.grayLight) colorWithAlphaComponent:0.8f];
        [self.arrowIcon setTitleColor:self.backgroundColor forState:UIControlStateNormal];
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}



- (void)startAnimating {
    if (self.hidden || ![WLNetwork sharedNetwork].reachable) {
        [self stopAnimating];
        return;
    }
    if ([self.arrowIcon.layer animationForKey:@"uploading"] != nil) return;
    [self.arrowIcon.layer addAnimation:self.animation forKey:@"uploading"];
    
}

- (CABasicAnimation *)animation {
    if (!_animation) {
        _animation = [CABasicAnimation animationWithKeyPath:@"transform"];
        _animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, -3, 0)];
        _animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeTranslation(0, -7, 0)];
        _animation.duration = 1.0f;
        _animation.repeatCount = FLT_MAX;
    }
    return _animation;
}

- (void)stopAnimating {
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
