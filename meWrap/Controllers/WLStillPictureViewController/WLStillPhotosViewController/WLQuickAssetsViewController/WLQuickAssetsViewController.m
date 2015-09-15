//
//  WLQuickAssetsViewController.m
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQuickAssetsViewController.h"
#import "StreamDataSource.h"
#import "WLAssetCell.h"
#import "WLToast.h"
#import "UIButton+Additions.h"
#import "PHPhotoLibrary+Helper.h"

@import Photos;

@interface WLQuickAssetsViewController () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) PHFetchResult *assets;
@property (strong, nonatomic) NSMutableArray *selectedAssets;

@property (strong, nonatomic) StreamDataSource *dataSource;
@property (weak, nonatomic) IBOutlet StreamView *streamView;
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
    self.streamView.layout = [[GridLayout alloc] initWithHorizontal:YES];
    self.dataSource = [StreamDataSource dataSourceWithStreamView:self.streamView];
    GridMetrics *metrics = [[GridMetrics alloc] initWithIdentifier:@"WLAssetCell" ratio:1];
    [metrics setSelection:^(StreamItem *item, id entry) {
        item.selected = [weakSelf selectAsset:entry];
    }];
    [metrics setPrepareAppearing:^(StreamItem *item, PHAsset *asset) {
        item.view.exclusiveTouch = !weakSelf.allowsMultipleSelection;
    }];
    [self.dataSource setDidLayoutItemBlock:^(StreamItem *item) {
        PHAsset *asset = item.entry;
        item.selected = [weakSelf.selectedAssets containsObject:asset.localIdentifier];
    }];
    
    [self.dataSource addMetrics:metrics];
    self.dataSource.numberOfGridColumns = 1;
    self.dataSource.sizeForGridColumns = 1;
    self.dataSource.layoutSpacing = 3;
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    self.assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    run_after_asap(^{
        if ([weakSelf.delegate respondsToSelector:@selector(quickAssetsViewControllerShouldPreselectFirstAsset:)]) {
            if ([weakSelf.delegate quickAssetsViewControllerShouldPreselectFirstAsset:weakSelf]) {
                [weakSelf selectAsset:[weakSelf.assets firstObject]];
            }
        }
        weakSelf.dataSource.items = weakSelf.assets;
    });
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (NSMutableArray *)selectedAssets {
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray array];
    }
    return _selectedAssets;
}

// MARK: - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    __weak typeof(self)weakSelf = self;
    run_in_main_queue(^{
        weakSelf.assets = [changeInstance changeDetailsForFetchResult:weakSelf.assets].fetchResultAfterChanges;
        weakSelf.dataSource.items = weakSelf.assets;
    });
}

#pragma mark - PGAssetCellDelegate

- (BOOL)selectAsset:(PHAsset *)asset {
    NSString *identifier = asset.localIdentifier;
    if ([self.selectedAssets containsObject:identifier]) {
        [self.selectedAssets removeObject:identifier];
        if ([self.delegate respondsToSelector:@selector(quickAssetsViewController:didDeselectAsset:)]) {
            [self.delegate quickAssetsViewController:self didDeselectAsset:asset];
        }
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
            return YES;
        }
    }
    return NO;
}

@end
