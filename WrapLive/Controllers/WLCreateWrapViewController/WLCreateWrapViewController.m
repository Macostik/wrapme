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
#import "WLWrapBroadcaster.h"
#import "NSString+Additions.h"
#import "WLBorderView.h"
#import "UIColor+CustomColors.h"
#import "WLAddressBook.h"
#import "WLInviteeCell.h"
#import "WLWrapEditSession.h"
#import "WLToast.h"
#import "WLContributor.h"
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
    // Do any additional setup after loading the view.
	
	self.imageView.url = [[self.pictures lastObject] medium];
    [self.nameField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.0f];
}

//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//	[super prepareForSegue:segue sender:sender];
//	if ([segue isContributorsSegue]) {
//		WLAddContributorsViewController* controller = segue.destinationViewController;
//        controller.contributors = self.editSession.contributors;
//        controller.invitees = self.editSession.invitees;
//        __weak typeof(self)weakSelf = self;
//        [controller setContactsBlock:^(NSArray *invitees) {
//            if (!weakSelf.editSession.invitees.nonempty) {
//                weakSelf.editSession.invitees = @[].mutableCopy;
//            }
//            [weakSelf.editSession addObjectToInvitees:invitees];
//        }];
//	}
//}

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
        [wrap save];
        [wrap broadcastCreation];
        [[WLUploading uploading:wrap] upload:^(id object) {
            weakSelf.view.userInteractionEnabled = YES;
            [weakSelf.delegate createWrapViewController:weakSelf didCreateWrap:wrap];
            [wrap uploadPictures:weakSelf.pictures];
        } failure:^(NSError *error) {
            weakSelf.view.userInteractionEnabled = YES;
            if ([error isNetworkError]) {
                [weakSelf.delegate createWrapViewController:weakSelf didCreateWrap:wrap];
                [wrap uploadPictures:weakSelf.pictures];
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
