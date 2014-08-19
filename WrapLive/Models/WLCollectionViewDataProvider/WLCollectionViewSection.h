//
//  WLCollectionViewSection.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLEntryCell.h"
#import "WLEntriesCollection.h"

@class WLCollectionViewDataProvider;

@interface WLCollectionViewSection : NSObject <UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (weak, nonatomic) WLCollectionViewDataProvider *dataProvider;

@property (strong, nonatomic) WLEntriesCollection entries;

@property (strong, nonatomic) NSString* reuseCellIdentifier;

@property (strong, nonatomic) NSString* reuseHeaderViewIdentifier;

@property (strong, nonatomic) NSString* reuseFooterViewIdentifier;

@property (strong, nonatomic) void (^configure) (id cell, id entry);

@property (strong, nonatomic) WLObjectBlock selection;

@property (strong, nonatomic) void (^change) (WLEntriesCollection entries);

@property (strong, nonatomic) id (^cell) (NSString* identifier, NSIndexPath* indexPath);

@property (nonatomic) CGSize defaultSize;

@property (strong, nonatomic) id defaultHeader;

@property (nonatomic) CGSize defaultHeaderSize;

@property (strong, nonatomic) id defaultFooter;

@property (nonatomic) CGSize defaultFooterSize;

@property (nonatomic) UIEdgeInsets defaultSectionInsets;

@property (nonatomic) CGFloat defaultMinimumLineSpacing;

- (instancetype)initWithCollectionView:(UICollectionView*)collectionView;

- (void)setup;

- (id)cellWithIdentifier:(NSString*)identifier indexPath:(NSIndexPath*)indexPath;

- (id)cell:(NSIndexPath*)indexPath;

- (CGSize)size:(NSIndexPath*)indexPath;

- (id)header:(NSIndexPath*)indexPath;

- (id)footer:(NSIndexPath*)indexPath;

- (CGSize)headerSize:(NSUInteger)section;

- (CGSize)footerSize:(NSUInteger)section;

- (NSUInteger)numberOfEntries;

- (CGFloat)minimumLineSpacing:(NSUInteger)section;

- (UIEdgeInsets)sectionInsets:(NSUInteger)section;

- (void)willChangeEntries:(WLEntriesCollection)entries;

- (void)didChangeEntries:(WLEntriesCollection)entries;

- (void)refresh:(WLOrderedSetBlock)success failure:(WLFailureBlock)failure;

- (void)select:(NSIndexPath*)indexPath;

@end
