//
//  AdobeUXImageEditorViewController+SharedEditing.m
//  moji
//
//  Created by Ravenpod on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "AdobeUXImageEditorViewController+SharedEditing.h"
#import "WLNavigationHelper.h"
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>

@implementation AdobeUXImageEditorViewController (SharedEditing)

+ (void)editImage:(UIImage *)image completion:(WLImageBlock)completion cancel:(WLBlock)cancel {
    AFPhotoEditorController* aviaryController = [AdobeUXImageEditorViewController editControllerWithImage:image completion:^(UIImage *image, AdobeUXImageEditorViewController *controller) {
        if (completion) completion(image);
        [controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    } cancel:^(AdobeUXImageEditorViewController *controller) {
        if (cancel) cancel();
        [controller.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
    [[UIWindow mainWindow].rootViewController presentViewController:aviaryController animated:NO completion:nil];
}

static WLImageEditingCompletionBlock _completionBlock = nil;
static WLImageEditingCancelBlock _cancelBlock = nil;

+ (AFPhotoEditorController*)editControllerWithImage:(UIImage*)image completion:(WLImageEditingCompletionBlock)completion cancel:(WLImageEditingCancelBlock)cancel {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AdobeImageEditorCustomization setSupportedIpadOrientations:@[@(UIInterfaceOrientationPortrait),@(UIInterfaceOrientationPortraitUpsideDown),@(UIInterfaceOrientationLandscapeLeft),@(UIInterfaceOrientationLandscapeRight)]];
        [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:@"a7929bf566694d579acb507eae697db1"
                                                                       clientSecret:@"b6fa1e1c-4f8c-4001-88a9-0251a099f890" enableSignUp:NO];
    });
    AdobeUXImageEditorViewController* aviaryController = [[self alloc] initWithImage:image];
    aviaryController.delegate = (id)[AdobeUXImageEditorViewController class];
    _completionBlock = completion;
    _cancelBlock = cancel;
    return aviaryController;
}

// MARK: - AdobeUXImageEditorViewControllerDelegate

+ (void)photoEditor:(AdobeUXImageEditorViewController *)editor finishedWithImage:(UIImage *)image {
    if (_completionBlock) _completionBlock(image, editor);
    _completionBlock = nil;
    _cancelBlock = nil;
}

+ (void)photoEditorCanceled:(AdobeUXImageEditorViewController *)editor {
    if (_cancelBlock) _cancelBlock(editor);
    _completionBlock = nil;
    _cancelBlock = nil;
}

@end
