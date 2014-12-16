//
//  PGPhotoGroupViewController.m
//  PressGram-iOS
//
//  Created by Ivanov Andrey on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLAssetsGroupViewController.h"
#import "WLAssetsViewController.h"
#import "WLAssetsGroupCell.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSObject+NibAdditions.h"
#import "UIViewController+Additions.h"
#import "SegmentedControl.h"
#import "NSDate+Formatting.h"

@interface WLAssetsGroupViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, WLAssetsGroupCellDelegate>

@property (strong, nonatomic) NSArray *groups;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *accessLabel;

@end

@implementation WLAssetsGroupViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"PHOTOS";
    
    [self.collectionView registerNib:[WLAssetsGroupCell nib] forCellWithReuseIdentifier:[WLAssetsGroupCell reuseIdentifier]];
    
	[self loadGroups];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadGroups)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    
    if (self.openCameraRoll) {
        WLAssetsViewController* controller = [[WLAssetsViewController alloc] initWithGroup:nil];
        controller.selectionBlock = self.selectionBlock;
        controller.mode = self.mode;
        controller.preselectFirstAsset = YES;
        [self.navigationController pushViewController:controller animated:NO];
    }
}

- (void)loadGroups {
    __weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[weakSelf.collectionView reloadData];
		[[ALAssetsLibrary library] groups:^(NSArray *groups) {
			weakSelf.groups = groups;
			[weakSelf.collectionView reloadData];
		} failure:^(NSError *error) {
			if (error.code == ALAssetsLibraryAccessUserDeniedError ||
				error.code == ALAssetsLibraryAccessGloballyDeniedError) {
				weakSelf.accessLabel.hidden = NO;
			}
		}];
	});
}

#pragma mark - Table View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.groups.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *WLAssetsGroupCellID = @"WLAssetsGroupCell";
	WLAssetsGroupCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:WLAssetsGroupCellID forIndexPath:indexPath];
	cell.item = self.groups[indexPath.item];
	cell.delegate = self;
	return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(collectionView.bounds.size.width, 60);
}

#pragma mark - PGAssetsGroupCellDelegate

- (void)assetsGroupCell:(WLAssetsGroupCell *)cell didSelectGroup:(ALAssetsGroup *)group {
	WLAssetsViewController* controller = [[WLAssetsViewController alloc] initWithGroup:group];
	controller.selectionBlock = self.selectionBlock;
    controller.mode = self.mode;
	[self pushViewController:controller animated:YES];
}

@end
