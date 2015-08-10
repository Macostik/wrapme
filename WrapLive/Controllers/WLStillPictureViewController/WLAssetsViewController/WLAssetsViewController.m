//
//  PGPhotoLibraryViewController.m
//  moji
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
#import "WLCollections.h"
#import "WLWrapView.h"
#import "WLBasicDataSource.h"

static NSUInteger WLAssetsSelectionLimit = 10;

@interface WLAssetsViewController () <WLAssetCellDelegate>

@property (strong, nonatomic) NSArray *assets;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSMutableArray *selectedAssets;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *doneButtonTrailingConstraint;

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

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
    if (self.isViewLoaded) {
        self.titleLabel.text = group.name;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    static NSUInteger WLAssetNumberOfColumns = 4;
    self.dataSource.minimumInteritemSpacing = self.dataSource.minimumLineSpacing = WLConstants.pixelSize;
    CGFloat size = (self.view.width - WLConstants.pixelSize * (WLAssetNumberOfColumns + 1))/WLAssetNumberOfColumns;
    self.dataSource.itemSize = CGSizeMake(size, size);
    self.dataSource.sectionTopInset = self.dataSource.sectionLeftInset = self.dataSource.sectionBottomInset = self.dataSource.sectionRightInset = WLConstants.pixelSize;
	 
    [self loadAssets];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetsLibraryChanged:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    self.titleLabel.text = self.group.name;
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
    self.dataSource.items = assets;
}

- (void)assetsLibraryChanged:(NSNotification*)notifiection {
    __weak WLAssetsViewController* weakSelf = self;
    
    [[ALAssetsLibrary library] groups:^(NSArray *groups) {
        for (ALAssetsGroup* group in groups) {
            if ([group isEqualToGroup:weakSelf.group])
            {
                weakSelf.group = group;
                [weakSelf loadAssets];
                return;
            }
        }
        
        [weakSelf.navigationController popViewControllerAnimated:NO];
    } failure:^(NSError *error) {
    }];
}

- (void)loadAssets {
    __weak typeof(self)weakSelf = self;
    if (self.group) {
        self.titleLabel.text = self.group.name;
        [self.group assets:^(NSArray *assets) {
            weakSelf.assets = assets;
            if (weakSelf.preselectFirstAsset && assets.count > 0) {
                [weakSelf selectAsset:[assets firstObject]];
                weakSelf.preselectFirstAsset = NO;
            }
        }];
    } else {
        self.titleLabel.text = self.group.name;
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
    __weak typeof(self)weakSelf = self;
    [self.delegate assetsViewController:self didSelectAssets:[self.selectedAssets map:^id(NSString* assetID) {
        return [weakSelf.assets select:^BOOL(ALAsset* asset) {
            return [asset.ID isEqualToString:assetID];
        }];
    }]];
}

#pragma mark - WLAssetCellDelegate

- (void)selectAsset:(ALAsset *)asset {
    CGSize size = asset.defaultRepresentation.dimensions;
    if (size.width == 0 && size.height == 0) {
        [WLToast showWithMessage:WLLS(@"invalid_image_error")];
    } else if (size.width < 100 || size.height < 100) {
        [WLToast showWithMessage:WLLS(@"too_small_image_error")];
    } else {
        if (self.mode == WLStillPictureModeDefault) {
            if ([self.selectedAssets containsObject:asset.ID]) {
                [self.selectedAssets removeObject:asset.ID];
            } else if (self.selectedAssets.count < WLAssetsSelectionLimit) {
                [self.selectedAssets addObject:asset.ID];
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
    [self.dataSource reload];
}

- (BOOL)assetCell:(WLAssetCell *)cell isSelectedAsset:(ALAsset *)asset {
    return [self.selectedAssets containsObject:asset.ID];
}

@end
