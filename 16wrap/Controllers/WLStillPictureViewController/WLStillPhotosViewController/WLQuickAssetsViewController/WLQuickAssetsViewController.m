//
//  WLQuickAssetsViewController.m
//  moji
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLQuickAssetsViewController.h"
#import "StreamDataSource.h"
#import "WLAssetCell.h"
#import "ALAssetsLibrary+Additions.h"
#import "WLToast.h"
#import "UIButton+Additions.h"
#import "WLCollections.h"
#import "WLWrapView.h"

@interface WLQuickAssetsViewController () <WLAssetCellDelegate>

@property (strong, nonatomic) NSArray *assets;
@property (strong, nonatomic) NSMutableArray *selectedAssets;

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UILabel *accessErrorLabel;

@end

@implementation WLQuickAssetsViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    _assets = assets;
    self.dataSource.items = assets;
}

- (void)assetsLibraryChanged:(NSNotification*)notifiection {
    [self performSelectorOnMainThread:@selector(loadAssets:) withObject:nil waitUntilDone:NO];
}

- (void)loadAssets:(WLBlock)success {
    __weak typeof(self)weakSelf = self;
    [[ALAssetsLibrary library] enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group) {
            if (weakSelf) {
                [group assets:^(NSArray *assets) {
                    weakSelf.assets = assets;
                    if (success) success();
                }];
            }
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
    NSString *identifier = asset.ID;
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
            [self.selectedAssets addObject:asset.ID];
            if ([self.delegate respondsToSelector:@selector(quickAssetsViewController:didSelectAsset:)]) {
                [self.delegate quickAssetsViewController:self didSelectAsset:asset];
            }
            [self.dataSource reload];
        }
    }
}

- (void)assetCell:(WLAssetCell *)cell didSelectAsset:(ALAsset *)asset {
    [self selectAsset:asset];
}

- (BOOL)assetCell:(WLAssetCell *)cell isSelectedAsset:(ALAsset *)asset {
    return [self.selectedAssets containsObject:asset.ID];
}

- (BOOL)assetCellAllowsMultipleSelection:(WLAssetCell *)cell {
    return self.allowsMultipleSelection;
}

@end
