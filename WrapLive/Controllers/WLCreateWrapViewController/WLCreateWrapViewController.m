//
//  WLCreateWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLCreateWrapViewController.h"
#import "WLContributorCell.h"
#import "WLWrap.h"
#import "WLAddContributorsViewController.h"
#import "NSArray+Additions.h"
#import "WLNavigation.h"
#import "WLAPIManager.h"
#import "WLWrapViewController.h"
#import "WLCameraViewController.h"
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "WLImageCache.h"
#import "WLImageFetcher.h"
#import "UIImage+Resize.h"
#import "UIView+Shorthand.h"
#import "WLUser.h"
#import "UIButton+Additions.h"
#import "WLEntryNotifier.h"
#import "NSString+Additions.h"
#import "WLBorderView.h"
#import "UIColor+CustomColors.h"
#import "WLAddressBook.h"
#import "WLInviteeCell.h"
#import "WLToast.h"
#import "WLPerson.h"
#import "WLButton.h"


@interface WLCreateWrapViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet WLImageView *imageView;

@property (weak, nonatomic) IBOutlet UIButton *createButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;



@end

@implementation WLCreateWrapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.imageView.url = [[self.pictures lastObject] medium];
    [self.nameField becomeFirstResponder];
}

#pragma mark - Actions

- (IBAction)cancel:(id)sender {
    [self.delegate createWrapViewControllerDidCancel:self];
}

- (IBAction)done:(WLButton*)sender {
    NSString* name = self.nameField.text;
    if (name.nonempty) {
        sender.loading = YES;
        __weak typeof(self)weakSelf = self;
        self.view.userInteractionEnabled = NO;
        WLWrap* wrap = [WLWrap wrap];
        wrap.name = name;
        [wrap notifyOnAddition];
        [[WLUploading uploading:wrap] upload:^(id object) {
            weakSelf.view.userInteractionEnabled = YES;
            [wrap uploadPictures:weakSelf.pictures];
            [weakSelf.delegate createWrapViewController:weakSelf didCreateWrap:wrap];
        } failure:^(NSError *error) {
            weakSelf.view.userInteractionEnabled = YES;
            if ([error isNetworkError]) {
                [wrap uploadPictures:weakSelf.pictures];
                [weakSelf.delegate createWrapViewController:weakSelf didCreateWrap:wrap];
            } else {
                sender.loading = NO;
                [error show];
                [wrap remove];
            }
        }];
    }
}

#pragma mark - UITextFieldDelegate

- (IBAction)textFieldDidChange:(UITextField *)sender {
	if (sender.text.length > WLWrapNameLimit) {
		sender.text = [sender.text substringToIndex:WLWrapNameLimit];
	}
    self.createButton.enabled = sender.text.nonempty;
}

@end
