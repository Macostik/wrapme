//
//  PGPhotoGroupViewController.m
//  moji
//
//  Created by Ivanov Andrey on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLAssetsGroupViewController.h"
#import "WLAssetsGroupCell.h"
#import "ALAssetsLibrary+Additions.h"
#import "NSObject+NibAdditions.h"
#import "SegmentedControl.h"
#import "WLNavigationHelper.h"
#import "WLWrapView.h"
#import "WLBasicDataSource.h"

@interface WLAssetsGroupViewController () <WLAssetsGroupCellDelegate>

@property (strong, nonatomic) NSArray *groups;

@property (weak, nonatomic) IBOutlet UILabel *accessLabel;

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

@end

@implementation WLAssetsGroupViewController

@dynamic delegate;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
	[self loadGroups];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loadGroups)
                                                 name:ALAssetsLibraryChangedNotification
                                               object:nil];
    
    if (self.openCameraRoll) {
        WLAssetsViewController* controller = [WLAssetsViewController instantiate:self.storyboard];
        controller.delegate = self.delegate;
        controller.mode = self.mode;
        controller.preselectFirstAsset = YES;
        controller.wrap = self.wrap;
        [self.navigationController pushViewController:controller animated:NO];
    }
}

- (void)setGroups:(NSArray *)groups {
    _groups = groups;
    self.dataSource.items = groups;
}

- (void)loadGroups {
    __weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[[ALAssetsLibrary library] groups:^(NSArray *groups) {
			weakSelf.groups = groups;
		} failure:^(NSError *error) {
			if (error.code == ALAssetsLibraryAccessUserDeniedError ||
				error.code == ALAssetsLibraryAccessGloballyDeniedError) {
				weakSelf.accessLabel.hidden = NO;
			}
		}];
	});
}

#pragma mark - PGAssetsGroupCellDelegate

- (void)assetsGroupCell:(WLAssetsGroupCell *)cell didSelectGroup:(ALAssetsGroup *)group {
	WLAssetsViewController* controller = [WLAssetsViewController instantiate:self.storyboard];
    controller.group = group;
	controller.delegate = self.delegate;
    controller.mode = self.mode;
    controller.wrap = self.wrap;
	[self pushViewController:controller animated:NO];
}

@end
