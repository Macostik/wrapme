//
//  WLCollectionView.m
//  moji
//
//  Created by Ravenpod on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionView.h"
#import "WLLoadingView.h"
#import "UIView+AnimationHelper.h"
#import "NSObject+NibAdditions.h"

static NSString *const WLContentSize = @"contentSize";
static CGFloat WLDefaultType = -1;

@interface WLCollectionView ()

@property (weak, nonatomic) IBOutlet WLLabel *placeholderTextLabel;

@property (assign, nonatomic) BOOL isShowPlacehoder;
@property (strong, nonatomic) UIView *placeholderView;
@property (strong, nonatomic) NSMapTable *placeholderMap;
@property (assign, nonatomic) NSInteger currentType;

@property (nonatomic) BOOL requestedReloadingData;

@property (nonatomic) NSUInteger reloadingDataLocksCount;

@end

@implementation WLCollectionView

- (void)awakeFromNib {
    [super awakeFromNib];
    [WLLoadingView registerInCollectionView:self];
    self.placeholderMap = [NSMapTable strongToStrongObjectsMapTable];
    [self addToCachePlaceholderWithName:self.nibNamePlaceholder byType:WLDefaultType];
    [self setPlaceholderByTupe:WLDefaultType];
    [self addObserver:self forKeyPath:WLContentSize options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)reloadData {
    if (self.reloadingDataLocksCount > 0) {
        self.requestedReloadingData = YES;
    } else {
        [super reloadData];
    }
}

- (void)lockReloadingData {
    self.reloadingDataLocksCount = MAX(0, self.reloadingDataLocksCount + 1);
}

- (void)unlockReloadingData {
    if (self.reloadingDataLocksCount > 0) {
        self.reloadingDataLocksCount = self.reloadingDataLocksCount - 1;
    }
    if (self.reloadingDataLocksCount == 0 && self.requestedReloadingData) {
        self.requestedReloadingData = NO;
        [super reloadData];
    }
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

- (void)setPlaceholderByTupe:(NSInteger)type {
    self.currentType = type;
}

- (BOOL)isDefaultPlaceholder {
    return self.currentType == WLDefaultType;
}

- (void)setDefaulPlaceholder {
    self.currentType = WLDefaultType;
}

- (void)addToCachePlaceholderWithName:(NSString *)placeholderName byType:(NSInteger)type {
    if (placeholderName.nonempty) {
        id object = [self.placeholderMap objectForKey:@(type)];
        if (object == nil) {
            [self.placeholderMap setObject:placeholderName forKey:@(type)];
        }
    }
}

- (UIView *)placeholderViewByType:(NSInteger)type {
    NSString *nibName = [self.placeholderMap objectForKey:@(type)];
    if (nibName == nil) {
        if (self.nibNamePlaceholder.nonempty) {
            nibName = [self.placeholderMap objectForKey:@(WLDefaultType)];
        } else {
            return nil;
        }
    }
     return [UIView loadFromNib:[UINib nibWithNibName:nibName bundle:nil] ownedBy:self];
}

- (void)setBackgroundPlaceholderByType:(NSInteger)type {
    UIView* placeholderView = [self placeholderViewByType:type];
    CGPoint offset = self.contentOffset;
    placeholderView.frame = CGRectMake(self.bounds.origin.x - offset.x, self.bounds.origin.y - offset.y, self.bounds.size.width, self.bounds.size.height);
    [self addSubview:placeholderView];
    if (self.layer.geometryFlipped != placeholderView.layer.geometryFlipped) {
        placeholderView.layer.geometryFlipped = self.layer.geometryFlipped;
    }
    self.placeholderView = placeholderView;
    self.placeholderTextLabel.text = self.placeholderText;
}

- (void)dealloc {
   [self removeObserver:self forKeyPath:WLContentSize context:NULL];
}

@end
