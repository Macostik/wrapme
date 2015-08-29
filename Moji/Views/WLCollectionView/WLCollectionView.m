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
//static CGFloat WLDefaultType;

@interface WLCollectionView ()

@property (weak, nonatomic) IBOutlet WLLabel *placeholderTextLabel;
@property (weak, nonatomic) IBOutlet SegmentedControl *segmentControl;

@property (strong, nonatomic) UIView *placeholderView;
@property (strong, nonatomic) NSMapTable *placeholderMap;

@property (nonatomic) BOOL requestedReloadingData;

@property (nonatomic) NSUInteger locks;

@end

@implementation WLCollectionView

static NSHashTable *collectionViews = nil;

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        if (!collectionViews) {
            collectionViews = [NSHashTable weakObjectsHashTable];
        }
        _placeholderMap = [NSMapTable strongToStrongObjectsMapTable];
        [collectionViews addObject:self];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [WLLoadingView registerInCollectionView:self];
    
    NSArray *nibNames = [self.nibNamePlaceholder componentsSeparatedByString:@","];
    for (short i = nibNames.count - 1; i >= 0; i--) {
        [self cachePlaceholderViewWithName:[nibNames[i] trim] byType:i];
        [self setIndex:i];
    }
    
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
        [self setPlaceholderByindex:self.index];
    } else if (self.placeholderView != nil) {
        [self.placeholderView removeFromSuperview];
        self.placeholderView = nil;
    }
}

- (IBAction)handleSegmenControl:(id)sender {
   NSUInteger index = [self.segmentControl.controls indexOfObject:sender];
    self.index = index;
    [self setupPlaceholder];
}

- (void)cachePlaceholderViewWithName:(NSString *)placeholderName byType:(NSInteger)type {
    UIView *view = [self.placeholderMap objectForKey:@(type)];
    if (view == nil && placeholderName.nonempty) {
        view = [UIView loadFromNib:[UINib nibWithNibName:placeholderName bundle:nil] ownedBy:self];
        if (view) {
             [self.placeholderMap setObject:view forKey:@(type)];
        }
    }
}

- (UIView *)placeholderViewByIndex:(NSInteger)index {
    UIView *view = [self.placeholderMap objectForKey:@(index)];
    if (view == nil && self.nibNamePlaceholder.nonempty) {
        view = [self.placeholderMap objectForKey:@(0)];
    }
    return view;
}

- (void)setPlaceholderByindex:(NSInteger)index {
    UIView* placeholderView = [self placeholderViewByIndex:index];
    if (_placeholderView != placeholderView) {
        [_placeholderView removeFromSuperview];
    }
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
