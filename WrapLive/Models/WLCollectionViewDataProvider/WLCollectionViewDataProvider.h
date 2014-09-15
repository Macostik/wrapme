//
//  WLCollectionViewDataProvider.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLCollectionViewSection.h"
#import "WLRefresher.h"

typedef NS_ENUM(NSUInteger, Direction) {
    DirectionUnknown,
    DirectionUp,
    DirectionDown
};

@interface WLCollectionViewDataProvider : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) IBOutletCollection(WLCollectionViewSection) NSMutableArray* sections;

@property (nonatomic) Direction direction;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray* animationViews;

+ (instancetype)dataProvider:(UICollectionView*)collectionView;

+ (instancetype)dataProvider:(UICollectionView*)collectionView sections:(NSArray*)sections;

+ (instancetype)dataProvider:(UICollectionView*)collectionView section:(WLCollectionViewSection*)section;

- (void)reload;

- (void)reload:(WLCollectionViewSection*)section;

- (void)connect;

- (void)setRefreshable;

- (void)setRefreshableWithStyle:(WLRefresherStyle)style contentMode:(UIViewContentMode)contentMode;

- (void)setRefreshableWithContentMode:(UIViewContentMode)contentMode;

- (void)setRefreshableWithStyle:(WLRefresherStyle)style;

@end

@interface WLCollectionViewSection (WLCollectionViewDataProvider)

- (void)reload;

@end
