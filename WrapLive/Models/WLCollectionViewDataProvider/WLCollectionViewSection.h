//
//  WLCollectionViewSection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLCollectionItemCell.h"

@class WLCollectionViewDataProvider;

@interface WLCollectionViewSection : NSObject

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (weak, nonatomic) WLCollectionViewDataProvider *dataProvider;

@property (strong, nonatomic) NSMutableOrderedSet* entries;

@property (strong, nonatomic) NSString* reuseCellIdentifier;

@property (strong, nonatomic) NSString* reuseHeaderViewIdentifier;

@property (strong, nonatomic) NSString* reuseFooterViewIdentifier;

@property (nonatomic) BOOL registerCellAfterAwakeFromNib;

@property (nonatomic) BOOL registerHeaderAfterAwakeFromNib;

@property (nonatomic) BOOL registerFooterAfterAwakeFromNib;

@property (strong, nonatomic) void (^configureCellBlock) (WLCollectionItemCell* cell, id entry);

- (id)cell:(NSIndexPath*)indexPath;

- (CGSize)size:(NSIndexPath*)indexPath;

- (id)header:(NSIndexPath*)indexPath;

- (id)footer:(NSIndexPath*)indexPath;

- (CGSize)headerSize:(NSIndexPath*)indexPath;

- (CGSize)footerSize:(NSIndexPath*)indexPath;

- (NSUInteger)numberOfEntries;

- (CGFloat)minimumLineSpacing:(NSUInteger)section;

- (UIEdgeInsets)sectionInsets:(NSUInteger)section;

@end
