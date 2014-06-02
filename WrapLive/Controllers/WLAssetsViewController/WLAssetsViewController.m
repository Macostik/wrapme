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

@interface WLAssetsViewController () <WLAssetCellDelegate>

@property (strong, nonatomic) NSArray *assets;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

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

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.titleLabel.text = self.group.name;
    
    [self.collectionView registerNib:[WLAssetCell nib] forCellWithReuseIdentifier:[WLAssetCell reuseIdentifier]];
    
    [self loadAssets];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(assetsLibraryChanged:)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
}

- (void)assetsLibraryChanged:(NSNotification*)notifiection
{
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

- (void)loadAssets
{
    __weak WLAssetsViewController* selfWeak = self;
    self.title = [self.group.name uppercaseString];
    [self.group assets:^(NSArray *assets) {
        selfWeak.assets = assets;
        [selfWeak.collectionView reloadData];
    }];
}

- (IBAction)back:(UIButton *)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - PSTCollectionViewDelegate

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    WLAssetCell *cell = [cv dequeueReusableCellWithReuseIdentifier:[WLAssetCell reuseIdentifier] forIndexPath:indexPath];
    cell.item = self.assets[indexPath.row];
	cell.delegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    ALAsset* asset = self.assets[indexPath.row];
    CGSize size = asset.defaultRepresentation.dimensions;
    if (size.width == 0 && size.height == 0) {
        [WLToast showWithMessage:@"This image is invalid. Please, choose another one."];
    } else if (size.width < 100 || size.height < 100) {
        [WLToast showWithMessage:@"This image is too small. Please, choose another one."];
    } else {
        if (self.selectionBlock) {
            self.selectionBlock(asset);
        }
    }
}

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

#pragma mark - PGAssetCellDelegate

- (void)assetCell:(WLAssetCell *)cell didSelectAsset:(ALAsset *)asset {
	
	CGSize size = asset.defaultRepresentation.dimensions;
	
	if (size.width == 0 && size.height == 0) {
		[WLToast showWithMessage:@"Your image is invalid. Please, choose another one."];
	} else if (size.width < 100 || size.height < 100) {
		[WLToast showWithMessage:@"Your image is too small. Please, choose another one."];
	} else if (self.selectionBlock) {
		self.selectionBlock(asset);
	}
}

@end
