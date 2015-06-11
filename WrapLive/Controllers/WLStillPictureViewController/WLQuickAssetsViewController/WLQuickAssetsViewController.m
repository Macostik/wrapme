//
//  WLQuickAssetsViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQuickAssetsViewController.h"
#import "WLBasicDataSource.h"
#import "WLAssetCell.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLToast.h"
#import "UIButton+Additions.h"
#import "NSArray+Additions.h"
#import "WLWrapView.h"

@interface WLQuickAssetsViewController ()

@property (strong, nonatomic) NSArray *assets;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *selectedAssets;

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UILabel *accessErrorLabel;

@end

@implementation WLQuickAssetsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadAssets];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetsLibraryChanged:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
}

- (NSMutableArray *)selectedAssets {
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray array];
    }
    return _selectedAssets;
}

- (void)setAssets:(NSArray *)assets {
    _assets = [assets selectObjects:^BOOL(ALAsset* asset) {
        return ![self.selectedAssets containsObject:asset.ID];
    }];
    self.dataSource.items = _assets;
}

- (void)assetsLibraryChanged:(NSNotification*)notifiection {
    [self loadAssets];
}

- (void)loadAssets {
    __weak typeof(self)weakSelf = self;
    [[ALAssetsLibrary library] enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            [group assets:^(NSArray *assets) {
                weakSelf.assets = assets;
            }];
            *stop = YES;
        }
    } failureBlock:^(NSError *error) {
        if (error.code == ALAssetsLibraryAccessUserDeniedError ||
            error.code == ALAssetsLibraryAccessGloballyDeniedError) {
            weakSelf.accessErrorLabel.hidden = NO;
        }
    }];
}

#pragma mark - PGAssetCellDelegate

- (void)selectAsset:(ALAsset *)asset {
    [self.selectedAssets addObject:asset.ID];
    self.assets = [self.assets arrayByRemovingObject:asset];
    [self.delegate assetsViewController:self didSelectAssets:@[asset]];
}

- (void)assetCell:(WLAssetCell *)cell didSelectAsset:(ALAsset *)asset {
    [self selectAsset:asset];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    if (indexPath) {
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    } else {
        [self.collectionView reloadData];
    }
}

@end
