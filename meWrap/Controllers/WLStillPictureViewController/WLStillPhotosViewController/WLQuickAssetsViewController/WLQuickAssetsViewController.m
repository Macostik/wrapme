//
//  WLQuickAssetsViewController.m
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQuickAssetsViewController.h"
#import "WLBasicDataSource.h"
#import "WLAssetCell.h"
#import "WLToast.h"
#import "UIButton+Additions.h"
#import "WLCollections.h"
#import "WLWrapView.h"

@import Photos;

@interface WLQuickAssetsViewController () <WLAssetCellDelegate, PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) NSMutableArray *selectedAssets;

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UILabel *accessErrorLabel;

@end

@implementation WLQuickAssetsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak typeof(self)weakSelf = self;
    [self loadAssets:^{
        BOOL preselectFirstAsset = NO;
        if ([weakSelf.delegate respondsToSelector:@selector(quickAssetsViewControllerShouldPreselectFirstAsset:)]) {
            preselectFirstAsset = [weakSelf.delegate quickAssetsViewControllerShouldPreselectFirstAsset:weakSelf];
        }
        if (preselectFirstAsset) {
            [weakSelf performSelector:@selector(selectAsset:) withObject:[weakSelf.assets firstObject] afterDelay:0.0f];
        }
    }];
    
    __weak WLBasicDataSource *dataSource = self.dataSource;
    [dataSource setItemSizeBlock:^CGSize(id item, NSUInteger index) {
        CGFloat size = dataSource.collectionView.height - dataSource.sectionBottomInset - dataSource.sectionTopInset;
        return CGSizeMake(size, size);
    }];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self]; 
}

- (NSMutableArray *)selectedAssets {
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray array];
    }
    return _selectedAssets;
}

- (void)setAssets:(NSArray *)assets {
    _assets = assets;
    self.dataSource.items = assets;
}

- (void)loadAssets:(WLBlock)success {
    NSMutableArray *assets = [NSMutableArray array];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    for (PHAsset *asset in fetchResult) {
        [assets addObject:asset];
    }
    self.assets = assets;
    if (success) success();
}

// MARK: - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self performSelectorOnMainThread:@selector(loadAssets:) withObject:nil waitUntilDone:NO];
}

#pragma mark - PGAssetCellDelegate

- (void)selectAsset:(PHAsset *)asset {
    NSString *identifier = asset.localIdentifier;
    if ([self.selectedAssets containsObject:identifier]) {
        [self.selectedAssets removeObject:identifier];
        if ([self.delegate respondsToSelector:@selector(quickAssetsViewController:didDeselectAsset:)]) {
            [self.delegate quickAssetsViewController:self didDeselectAsset:asset];
        }
        [self.dataSource reload];
    } else {
        BOOL shouldSelect = YES;
        if ([self.delegate respondsToSelector:@selector(quickAssetsViewController:shouldSelectAsset:)]) {
            shouldSelect = [self.delegate quickAssetsViewController:self shouldSelectAsset:asset];
        }
        if (shouldSelect) {
            [self.selectedAssets addObject:asset.localIdentifier];
            if ([self.delegate respondsToSelector:@selector(quickAssetsViewController:didSelectAsset:)]) {
                [self.delegate quickAssetsViewController:self didSelectAsset:asset];
            }
            [self.dataSource reload];
        }
    }
}

- (void)assetCell:(WLAssetCell *)cell didSelectAsset:(PHAsset *)asset {
    [self selectAsset:asset];
}

- (BOOL)assetCell:(WLAssetCell *)cell isSelectedAsset:(PHAsset *)asset {
    return [self.selectedAssets containsObject:asset.localIdentifier];
}

- (BOOL)assetCellAllowsMultipleSelection:(WLAssetCell *)cell {
    return self.allowsMultipleSelection;
}

@end
