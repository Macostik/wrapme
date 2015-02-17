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
static CGFloat WLDefaultType = -1;

@interface WLCollectionView ()

@property (assign, nonatomic) BOOL isShowPlacehoder;
@property (strong, nonatomic) UIView *placeholderView;
@property (strong, nonatomic) NSMapTable *placeholderMap;
@property (assign, nonatomic) NSInteger currentType;

@end

@implementation WLCollectionView

- (void)awakeFromNib {
    [super awakeFromNib];
    [WLLoadingView registerInCollectionView:self];
    self.placeholderMap = [NSMapTable strongToWeakObjectsMapTable];
    self.currentType = WLDefaultType;
    [self setPlaceholderWithName:self.nibNamePlaceholder byType:WLDefaultType];
    [self addObserver:self forKeyPath:WLContentSize options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:WLContentSize]) {
        if (self.contentSize.width == 0 || self.contentSize.height == 0) {
            if (self.placeholderView != nil) return;
            [self setBackgroundPlaceholderByType:self.currentType];
        } else {
            if (self.placeholderView != nil) {
                [self.placeholderView removeFromSuperview];
                self.placeholderView = nil;
            }
        }
    }
}

- (BOOL)isDefaultPlaceholder {
    return self.currentType == WLDefaultType;
}

- (void)setDefaulPlaceholder {
    self.currentType = WLDefaultType;
}

- (void)setPlaceholderWithName:(NSString *)placeholderName byType:(NSInteger)type {
    if (placeholderName.nonempty) {
        id object = [self.placeholderMap objectForKey:@(type)];
        if (object == nil) {
            [self.placeholderMap setObject:placeholderName forKey:@(type)];
            self.currentType = type;
        }
    } else {
        [self setDefaulPlaceholder];
    }
}

- (UIView *)placeholderViewByType:(NSInteger)type {
    NSString *nibName = [self.placeholderMap objectForKey:@(type)];
    if (nibName == nil) {
        if (self.nibNamePlaceholder.nonempty) {
              nibName = [self.placeholderMap objectForKey:self.nibNamePlaceholder];
        } else {
            return nil;
        }
    }
     return [UIView loadFromNib:[UINib nibWithNibName:nibName bundle:nil] ownedBy:nil];
}

- (void)setBackgroundPlaceholderByType:(NSInteger)type {
    UIView* placeholderView = [self placeholderViewByType:type];
    placeholderView.frame = self.bounds;
    [self addSubview:placeholderView];
    if (!CGAffineTransformEqualToTransform(self.transform, CGAffineTransformIdentity)) {
        placeholderView.transform = CGAffineTransformInvert(self.transform);
    }
    self.placeholderView = placeholderView;
}

- (void)dealloc {
   [self removeObserver:self forKeyPath:WLContentSize context:NULL];
}

@end
