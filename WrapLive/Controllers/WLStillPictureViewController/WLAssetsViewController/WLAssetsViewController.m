//
//  PGPhotoLibraryViewController.m
//  PressGram-iOS
//
//  Created by Andrey Ivanov on 30.05.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLAssetsViewController.h"
#import "WLAssetCell.h"
#import "ALAssetsLibrary+Additions.h"
#import "UIImage+Resize.h"
#import "NSObject+NibAdditions.h"
#import "WLToast.h"
#import "UIButton+Additions.h"
#import "NSArray+Additions.h"
#import "WLWrapView.h"

static NSUInteger WLAssetsSelectionLimit = 10;

@interface WLAssetsViewController () <WLAssetCellDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSArray *assets;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray *selectedAssets;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doneButtonTrailingConstraint;

@property (readonly, nonatomic) BOOL horizontal;

@end

@implementation WLAssetsViewController

@dynamic delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithGroup:(ALAssetsGroup *)group {
    self = [super initWithNibName:@"WLAssetsViewController" bundle:nil];
    if (self) {
        self.group = group;
    }
    return self;
}

- (void)setGroup:(ALAssetsGroup *)group {
    _group = group;
    if (self.isViewLoaded && !self.horizontal) {
        self.titleLabel.text = group.name;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
	 
    [self loadAssets];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetsLibraryChanged:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    if (!self.horizontal) {
        self.titleLabel.text = self.group.name;
        if (self.mode != WLStillPictureModeDefault) {
            self.doneButton.hidden = YES;
        } else {
            self.doneButtonTrailingConstraint.constant = -self.doneButton.width;
        }
        
        if (self.wrapView.y == 0) {
            self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(self.wrapView.height, 0, 0, 0);
        } else {
            self.collectionView.contentInset = self.collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, self.wrapView.height, 0);
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.horizontal) {
        [self.spinner stopAnimating];
        self.doneButton.hidden = (self.mode != WLStillPictureModeDefault);
    }
}

- (BOOL)horizontal {
    return [(UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout scrollDirection] == UICollectionViewScrollDirectionHorizontal;
}

- (NSMutableArray *)selectedAssets {
    if (!_selectedAssets) {
        _selectedAssets = [NSMutableArray array];
    }
    return _selectedAssets;
}

- (void)setAssets:(NSArray *)assets {
    _assets = assets;
    if (self.selectedAssets.nonempty) {
        [self.selectedAssets setArray:[self.assets map:^id(ALAsset* asset) {
            for (ALAsset* selectedAsset in self.selectedAssets) {
                if ([selectedAsset isEqualToAsset:asset]) {
                    return asset;
                }
            }
            return nil;
        }]];
    }
}

- (void)assetsLibraryChanged:(NSNotification*)notifiection {
    __weak WLAssetsViewController* selfWeak = self;
    
    [[ALAssetsLibrary library] groups:^(NSArray *groups) {
        for (ALAssetsGroup* group in groups) {
            if ([group isEqualToGroup:selfWeak.group])
            {
                selfWeak.group = group;
                [selfWeak loadAssets];
                return;
            }
        }
        
        if (selfWeak.horizontal) {
            selfWeak.assets = nil;
        } else {
            [selfWeak.navigationController popViewControllerAnimated:NO];
        }
    } failure:^(NSError *error) {
    }];
}

- (void)loadAssets {
    __weak typeof(self)weakSelf = self;
    if (self.group) {
        self.title = [self.group.name uppercaseString];
        [self.group assets:^(NSArray *assets) {
            weakSelf.assets = assets;
            if (weakSelf.preselectFirstAsset && assets.count > 0) {
                [weakSelf selectAsset:[assets firstObject]];
                weakSelf.preselectFirstAsset = NO;
            }
            [weakSelf.collectionView reloadData];
        }];
    } else {
        self.title = [self.group.name uppercaseString];
        [[ALAssetsLibrary library] enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group) {
                weakSelf.group = group;
                [weakSelf loadAssets];
                *stop = YES;
            }
        } failureBlock:^(NSError *error) {
            
        }];
    }
}

- (IBAction)done:(id)sender {
    self.doneButton.hidden = YES;
    [self.spinner startAnimating];
    [self.delegate assetsViewController:self didSelectAssets:self.selectedAssets];
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
