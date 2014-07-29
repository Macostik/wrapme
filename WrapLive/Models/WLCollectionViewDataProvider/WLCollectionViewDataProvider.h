//
//  WLCollectionViewDataProvider.h
//  WrapLive
//
//  Created by Sergey Maximenko on 7/29/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WLCollectionViewSection.h"

@interface WLCollectionViewDataProvider : NSObject <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UICollectionView* collectionView;

@property (strong, nonatomic) IBOutlet NSMutableOrderedSet* sections;

- (void)reload;

- (void)reload:(WLCollectionViewSection*)section;

@end

@interface WLCollectionViewSection (WLCollectionViewDataProvider)

- (void)reload;

@end
