//
//  WLDataSource.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLRefresher.h"
#import "WLPaginatedSet+WLBaseOrderedCollection.h"

typedef NS_ENUM(NSUInteger, WLDataSourceScrollDirection) {
    WLDataSourceScrollDirectionUnknown,
    WLDataSourceScrollDirectionUp,
    WLDataSourceScrollDirectionDown
};

@interface WLDataSource : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (nonatomic) WLDataSourceScrollDirection direction;

@property (strong, nonatomic) IBInspectable NSString* cellIdentifier;

@property (strong, nonatomic) IBInspectable NSString* headerIdentifier;

@property (strong, nonatomic) IBInspectable NSString* footerIdentifier;

@property (nonatomic) IBInspectable CGSize itemSize;

@property (nonatomic) IBInspectable CGSize headerSize;

@property (nonatomic) IBInspectable CGSize footerSize;

@property (nonatomic) IBInspectable CGFloat sectionTopInset;

@property (nonatomic) IBInspectable CGFloat sectionBottomInset;

@property (nonatomic) IBInspectable CGFloat sectionLeftInset;

@property (nonatomic) IBInspectable CGFloat sectionRightInset;

@property (nonatomic) IBInspectable CGFloat minimumLineSpacing;

@property (nonatomic) IBInspectable CGFloat minimumInteritemSpacing;

@property (nonatomic) NSUInteger numberOfItems;

@property (strong, nonatomic) NSUInteger (^numberOfItemsBlock) (void);

@property (strong, nonatomic) NSString* (^cellIdentifierForItemBlock) (id item, NSUInteger index);

@property (strong, nonatomic) void (^configureCellForItemBlock) (id cell, id item);

@property (strong, nonatomic) CGSize (^itemSizeBlock) (id item, NSUInteger index);

@property (strong, nonatomic) CGSize (^headerSizeBlock) (void);

@property (strong, nonatomic) CGSize (^footerSizeBlock) (void);

@property (strong, nonatomic) WLObjectBlock selectionBlock;

@property (strong, nonatomic) void (^refreshBlock) (WLObjectBlock success, WLFailureBlock failure);

+ (instancetype)dataSource:(UICollectionView*)collectionView;

- (void)awakeAfterInit;

- (id)itemAtIndex:(NSUInteger)index;

- (NSUInteger)indexFromIndexPath:(NSIndexPath*)indexPath;

- (NSString*)cellIdentifierForItem:(id)item atIndex:(NSUInteger)index;

- (void)reload;

- (void)connect;

- (void)setRefreshable;

- (void)setRefreshableWithStyle:(WLRefresherStyle)style contentMode:(UIViewContentMode)contentMode;

- (void)setRefreshableWithContentMode:(UIViewContentMode)contentMode;

- (void)setRefreshableWithStyle:(WLRefresherStyle)style;

- (void)refresh:(WLObjectBlock)success failure:(WLFailureBlock)failure;

- (void)refresh;

@end