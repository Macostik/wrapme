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
        return [self.selectedAssets containsObject:asset.ID];
    }];
    self.dataSource.items = self.assets;
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
        
    }];
}

#pragma mark - PSTCollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WLAssetCell *cell = [cv dequeueReusableCellWithReuseIdentifier:[WLAssetCell reuseIdentifier] forIndexPath:indexPath];
    cell.item = self.assets[indexPath.row];
    cell.delegate = self;
    cell.checked = [self.selectedAssets containsObject:cell.item];
    return cell;
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return self.assets.count;
}

static NSUInteger WLAssetNumberOfColumns = 4;

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.horizontal) {
        return collectionViewLayout.itemSize;
    }
    CGFloat size = (collectionView.width - WLConstants.pixelSize * (WLAssetNumberOfColumns + 1))/WLAssetNumberOfColumns;
    return CGSizeMake(size, size);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (self.horizontal) {
        return collectionViewLayout.sectionInset;
    }
    return UIEdgeInsetsMake(WLConstants.pixelSize, WLConstants.pixelSize, self.wrapView.height, WLConstants.pixelSize);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (self.horizontal) {
        return collectionViewLayout.minimumLineSpacing;
    }
    return WLConstants.pixelSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (self.horizontal) {
        return collectionViewLayout.minimumInteritemSpacing;
    }
    return WLConstants.pixelSize;
}


#pragma mark - PGAssetCellDelegate

- (void)selectAsset:(ALAsset *)asset {
    if (self.horizontal) {
        [self.delegate assetsViewController:self didSelectAssets:@[asset]];
        return;
    }
    CGSize size = asset.defaultRepresentation.dimensions;
    if (size.width == 0 && size.height == 0) {
        [WLToast showWithMessage:WLLS(@"invalid_image_error")];
    } else if (size.width < 100 || size.height < 100) {
        [WLToast showWithMessage:WLLS(@"too_small_image_error")];
    } else {
        if (self.mode == WLStillPictureModeDefault) {
            if ([self.selectedAssets containsObject:asset]) {
                [self.selectedAssets removeObject:asset];
            } else if (self.selectedAssets.count < WLAssetsSelectionLimit) {
                [self.selectedAssets addObject:asset];
            } else {
                [WLToast showWithMessage:WLLS(@"upload_photos_limit_error")];
            }
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationBeginsFromCurrentState:YES];
            self.doneButtonTrailingConstraint.constant = self.selectedAssets.nonempty ? 0 : -self.doneButton.width;
            [self.doneButton layoutIfNeeded];
            [UIView commitAnimations];
        } else {
            [self.delegate assetsViewController:self didSelectAssets:@[asset]];
        }
    }
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
