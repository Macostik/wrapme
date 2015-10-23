//
//  WLQuickAssetsViewController.m
//  meWrap
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQuickAssetsViewController.h"
#import "StreamDataSource.h"
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
    self.streamView.layout = [[SquareLayout alloc] initWithHorizontal:YES];
    self.dataSource = [StreamDataSource dataSourceWithStreamView:self.streamView];
    StreamMetrics *metrics = [[StreamMetrics alloc] initWithIdentifier:@"AssetCell"];
    [metrics setSelection:^(StreamItem *item, id entry) {
        item.selected = [weakSelf selectAsset:entry];
    }];
    [metrics setPrepareAppearing:^(StreamItem *item, PHAsset *asset) {
        item.view.exclusiveTouch = weakSelf.mode != WLStillPictureModeDefault;
    }];
    [self.dataSource setDidLayoutItemBlock:^(StreamItem *item) {
        PHAsset *asset = item.entry;
        item.selected = [weakSelf.selectedAssets containsObject:asset.localIdentifier];
    }];
    
    [self.dataSource addMetrics:metrics];
    self.dataSource.numberOfGridColumns = 1;
    self.dataSource.sizeForGridColumns = 1;
    self.dataSource.layoutSpacing = 3;
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)setMode:(WLStillPictureMode)mode {
    _mode = mode;
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    if (self.mode == WLStillPictureModeDefault) {
        self.assets = [PHAsset fetchAssetsWithOptions:options];
    } else {
        self.assets = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:options];
    }
    if ([self.delegate respondsToSelector:@selector(quickAssetsViewControllerShouldPreselectFirstAsset:)]) {
        if ([self.delegate quickAssetsViewControllerShouldPreselectFirstAsset:self]) {
            [self selectAsset:[self.assets firstObject]];
        }
    }
    self.dataSource.items = self.assets;
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
        PHFetchResult *assets = [changeInstance changeDetailsForFetchResult:weakSelf.assets].fetchResultAfterChanges;
        if (assets) {
            weakSelf.dataSource.items = weakSelf.assets = assets;
        }
    });
}

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
