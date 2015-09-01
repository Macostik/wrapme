//
//  WLCollectionView.m
//  moji
//
//  Created by Ravenpod on 11/14/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLCollectionView.h"
#import "WLLoadingView.h"
#import "SegmentedControl.h"
#import "UIView+AnimationHelper.h"
#import "NSObject+NibAdditions.h"

static NSString *const WLContentSize = @"contentSize";

@interface WLCollectionView ()

@property (weak, nonatomic) IBOutlet WLLabel *placeholderTextLabel;

@property (strong, nonatomic) UIView *placeholderView;

@property (nonatomic) BOOL requestedReloadingData;

@property (nonatomic) NSUInteger locks;

@end

@implementation WLCollectionView

@dynamic dataSource;

static NSHashTable *collectionViews = nil;

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        if (!collectionViews) {
            collectionViews = [NSHashTable weakObjectsHashTable];
        }
        [collectionViews addObject:self];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [WLLoadingView registerInCollectionView:self];
    [self addObserver:self forKeyPath:WLContentSize options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)reloadData {
    if (self.locks > 0) {
        self.requestedReloadingData = YES;
    } else {
        [super reloadData];
    }
}

- (void)lock {
    self.locks = MAX(0, self.locks + 1);
}

+ (void)lock {
    for (WLCollectionView *collectionView in collectionViews) {
        [collectionView lock];
    }
}

+ (void)unlock {
    for (WLCollectionView *collectionView in collectionViews) {
        [collectionView unlock];
    }
}

- (void)unlock {
    if (self.locks > 0) {
        self.locks = self.locks - 1;
    }
    if (self.locks == 0 && self.requestedReloadingData) {
        self.requestedReloadingData = NO;
        [super reloadData];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:WLContentSize]) {
        [self setupPlaceholder];
    }
}

- (void)setupPlaceholder {
    if (self.contentSize.width == 0 || self.contentSize.height == 0) {
        NSString *placeholderName = self.nibNamePlaceholder;
        if ([self.dataSource respondsToSelector:@selector(placeholderNameOfCollectionView:)]) {
            placeholderName = [self.dataSource placeholderNameOfCollectionView:self];
        }
        
        if (placeholderName.nonempty && !(self.placeholderView && [self.nibNamePlaceholder isEqualToString:placeholderName])) {
            self.nibNamePlaceholder = placeholderName;
            [self.placeholderView removeFromSuperview];
            UIView *placeholderView = [UIView loadFromNib:[UINib nibWithNibName:placeholderName bundle:nil] ownedBy:self];
            if (placeholderView != nil) {
                placeholderView.frame = self.bounds;
                [self addSubview:placeholderView];
                if (self.layer.geometryFlipped != placeholderView.layer.geometryFlipped) {
                    placeholderView.layer.geometryFlipped = self.layer.geometryFlipped;
                }
                self.placeholderView = placeholderView;
                self.placeholderTextLabel.text = self.placeholderText;
            }
        }
    } else if (self.placeholderView != nil) {
        [self.placeholderView removeFromSuperview];
        self.placeholderView = nil;
    }
}

- (void)dealloc {
   [self removeObserver:self forKeyPath:WLContentSize context:NULL];
}

@end
