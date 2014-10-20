//
//  WLEditViewController.m
//  WrapLive
//
//  Created by Yuriy Granchenko on 10.07.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEditViewController.h"
#import "UIView+Shorthand.h"
#import "UIImage+Resize.h"
#import "WLEntryManager.h"
#import "WLNavigation.h"
#import "UIView+AnimationHelper.h"
#import "UIView+QuatzCoreAnimations.h"
#import "WLImageFetcher.h"
#import "WLButton.h"
#import "NSError+WLAPIManager.h"

@interface WLEditViewController ()

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet WLButton *doneButton;

@end

@implementation WLEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupEditableUserInterface];
}

- (void)setEditSession:(WLEditSession *)editSession {
    _editSession = editSession;
    editSession.delegate = self;
}

- (void)setupEditableUserInterface {
    
}

- (void)validate:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(nil);
}

- (void)apply:(WLObjectBlock)success failure:(WLFailureBlock)failure {
    if (success) success(nil);
}

- (IBAction)done:(WLButton*)sender {
    [self.view endEditing:YES];
	__weak typeof(self)weakSelf = self;
    [self validate:^(id object){
        [weakSelf lock];
        sender.loading = YES;
        [weakSelf.editSession apply];
        [weakSelf apply:^(id object){
            [weakSelf.navigationController popViewControllerAnimated:YES];
        } failure:^(NSError *error) {
            [weakSelf.editSession reset];
            [error show];
            sender.loading = NO;
            [weakSelf unlock];
        }];
    } failure:^(NSError *error) {
        [error show];
    }];
}

- (IBAction)cancel:(id)sender {
    [self.editSession clean];
    [self setupEditableUserInterface];
    [self.view endEditing:YES];
}

- (void)lock {
	for (UIView* subview in self.view.subviews) {
		subview.userInteractionEnabled = NO;
	}
}

- (void)unlock {
	for (UIView* subview in self.view.subviews) {
		subview.userInteractionEnabled = YES;
	}
}

#pragma mark - WLEditSessionDelegate

- (void)editSession:(WLEditSession *)session hasChanges:(BOOL)hasChanges {
    self.doneButton.hidden = self.cancelButton.hidden = !hasChanges;
    [self.cancelButton setAlpha:hasChanges ? 1 : 0 animated:YES];
    [self.doneButton setAlpha:hasChanges ? 1 : 0 animated:YES];
}

@end
