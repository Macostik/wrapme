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
#import "UIViewController+Additions.h"
#import "NSObject+NibAdditions.h"
#import "WLToast.h"
#import "UIButton+Additions.h"
#import "NSArray+Additions.h"

static NSUInteger WLAssetsSelectionLimit = 10;

@interface WLAssetsViewController () <WLAssetCellDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSArray *assets;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray *selectedAssets;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doneButtonTrailingConstraint;

@end

@implementation WLAssetsViewController

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
    if (self.isViewLoaded) {
        self.titleLabel.text = group.name;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.titleLabel.text = self.group.name;
        
    [self loadAssets];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetsLibraryChanged:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    if (self.mode != WLStillPictureModeDefault) {
        self.doneButton.hidden = YES;
    } else {
        self.doneButtonTrailingConstraint.constant = -self.doneButton.width;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.spinner stopAnimating];
    self.doneButton.hidden = (self.mode != WLStillPictureModeDefault);
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
        
        [selfWeak.navigationController popViewControllerAnimated:YES];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat size = (collectionView.width - WLConstants.pixelSize * (WLAssetNumberOfColumns + 1))/WLAssetNumberOfColumns;
    return CGSizeMake(size, size);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(WLConstants.pixelSize, WLConstants.pixelSize, WLConstants.pixelSize, WLConstants.pixelSize);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return WLConstants.pixelSize;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return WLConstants.pixelSize;
}


#pragma mark - PGAssetCellDelegate

- (void)selectAsset:(ALAsset *)asset {
    CGSize size = asset.defaultRepresentation.dimensions;
    if (size.width == 0 && size.height == 0) {
        [WLToast showWithMessage:WLLS(@"Your image is invalid. Please, choose another one.")];
    } else if (size.width < 100 || size.height < 100) {
        [WLToast showWithMessage:WLLS(@"Your image is too small. Please, choose another one.")];
    } else {
        if (self.mode == WLStillPictureModeDefault) {
            if ([self.selectedAssets containsObject:asset]) {
                [self.selectedAssets removeObject:asset];
            } else if (self.selectedAssets.count < WLAssetsSelectionLimit) {
                [self.selectedAssets addObject:asset];
            } else {
                [WLToast showWithMessage:WLLS(@"Sorry, you cannot upload more than 10 pictures at a time")];
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
