//
//  WLCollectionView.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionView.h"
#import "WLLoadingView.h"
#import "NSString+Additions.h"
#import "UIView+Shorthand.h"
#import "UIView+AnimationHelper.h"
#import "NSObject+NibAdditions.h"

static NSString *const WLContentSize = @"contentSize";

@interface WLCollectionView ()

@property (assign, nonatomic) BOOL isShowPlacehoder;
@property (strong, nonatomic) UIView *placeholderView;

@end

@implementation WLCollectionView

- (void)awakeFromNib {
    [super awakeFromNib];
    [WLLoadingView registerInCollectionView:self];
    if (self.nibNamePlaceholder || self.modeNibNamePlaceholder) {
        [self addObserver:self forKeyPath:WLContentSize options:NSKeyValueObservingOptionNew context:NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:WLContentSize]) {
        if (self.contentSize.width == 0 || self.contentSize.height == 0) {
            if (self.placeholderView != nil) return;
            [self setBackgroundPlaceholder];
        } else {
            if (self.placeholderView != nil) {
                [self.placeholderView removeFromSuperview];
                self.placeholderView = nil;
            }
        }
    }
}

- (void)setBackgroundPlaceholder {
    NSString *currentPlaceholderString = nil;
    switch (self.placeholderMode) {
        case WLManualPlaceholderMode:
            currentPlaceholderString = self.modeNibNamePlaceholder;
            break;
        default:
            currentPlaceholderString = self.nibNamePlaceholder;
            break;
    }
    UIView* placeholderView = [UIView loadFromNib:[UINib nibWithNibName:currentPlaceholderString bundle:nil] ownedBy:nil];
    placeholderView.frame = self.bounds;
    [self addSubview:placeholderView];
    if (!CGAffineTransformEqualToTransform(self.transform, CGAffineTransformIdentity)) {
        placeholderView.transform = CGAffineTransformInvert(self.transform);
    }
    self.placeholderView = placeholderView;
}

- (void)dealloc {
    if (self.nibNamePlaceholder || self.modeNibNamePlaceholder) [self removeObserver:self forKeyPath:WLContentSize context:NULL];
}

@end
