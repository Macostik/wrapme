//
//  WLImageEditorSession.m
//  meWrap
//
//  Created by Sergey Maximenko on 10/20/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "WLImageEditorSession.h"
#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>
#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>

@interface WLImageEditorSession ()

@end

@implementation WLImageEditorSession

+ (void)editImage:(UIImage *)image completion:(WLImageBlock)completion cancel:(WLBlock)cancel {
    UIViewController *presentingViewController = [UIWindow mainWindow].rootViewController;
    AdobeUXImageEditorViewController* controller = (id)[self editControllerWithImage:image completion:^(UIImage *image) {
        if (completion) completion(image);
        [presentingViewController dismissViewControllerAnimated:NO completion:nil];
    } cancel:^ {
        if (cancel) cancel();
        [presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
    
    [presentingViewController presentViewController:controller animated:NO completion:nil];
}

+ (AdobeUXImageEditorViewController*)editControllerWithImage:(UIImage*)image completion:(WLImageEditingCompletionBlock)completion cancel:(WLImageEditingCancelBlock)cancel {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [AdobeImageEditorCustomization setSupportedIpadOrientations:@[@(UIInterfaceOrientationPortrait),@(UIInterfaceOrientationPortraitUpsideDown),@(UIInterfaceOrientationLandscapeLeft),@(UIInterfaceOrientationLandscapeRight)]];
        [[AdobeUXAuthManager sharedManager] setAuthenticationParametersWithClientID:@"a7929bf566694d579acb507eae697db1"
                                                                       clientSecret:@"b6fa1e1c-4f8c-4001-88a9-0251a099f890" enableSignUp:NO];
    });
    AdobeUXImageEditorViewController* controller = [[AdobeUXImageEditorViewController alloc] initWithImage:image];
    [controller enqueueHighResolutionRenderWithImage:image completion:^(UIImage *result, NSError *error) {
        if (result) {
            if (completion) completion(result);
        } else {
            if (cancel) cancel();
        }
    }];
    return controller;
}

@end
