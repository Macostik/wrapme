//
//  WLStoryboardSegue.m
//  WrapLive
//
//  Created by Sergey Maximenko on 10/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLStoryboardSegue.h"
#import "NSString+Additions.h"
#import "GCDHelper.h"
#import "WLNavigationHelper.h"

@implementation WLSetValueSegue

- (void)perform {
    UINavigationController* navigationController = [self.sourceViewController navigationController];
    if ([self.identifier rangeOfString:@"->"].location != NSNotFound) {
        [self setValueAndPush];
    } else if ([self.identifier rangeOfString:@"<-"].location != NSNotFound) {
        [self setValueAndPop];
    } else {
        NSDictionary *options = [NSJSONSerialization JSONObjectWithData:[self.identifier dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        if (options) {
            [self performWithOptions:options destinationViewController:self.destinationViewController];
        } else {
            [navigationController pushViewController:self.destinationViewController animated:YES];
        }
    }
}

- (void)setValueAndPush {
    NSArray* keyPaths = [self.identifier componentsSeparatedByString:@"->"];
    if (keyPaths.count == 2) {
        NSString* sourceValueKeyPath = [keyPaths objectAtIndex:0];
        NSString* destinationValueKeyPath = [keyPaths objectAtIndex:1];
        if (sourceValueKeyPath.nonempty && destinationValueKeyPath.nonempty) {
            id value = [self.sourceViewController valueForKeyPath:sourceValueKeyPath];
            if (value) {
                [self.destinationViewController setValue:value forKeyPath:destinationValueKeyPath];
            }
        }
    }
    [[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:YES];
}

- (void)setValueAndPop {
    UINavigationController* navigationController = [self.sourceViewController navigationController];
    [navigationController popViewControllerAnimated:YES];
    NSArray* keyPaths = [self.identifier componentsSeparatedByString:@"<-"];
    if (keyPaths.count == 2) {
        NSString* sourceValueKeyPath = [keyPaths objectAtIndex:1];
        NSString* destinationValueKeyPath = [keyPaths objectAtIndex:0];
        if (sourceValueKeyPath.nonempty && destinationValueKeyPath.nonempty) {
            run_after(0.1f,^{
                id value = [self.sourceViewController valueForKeyPath:sourceValueKeyPath];
                if (value) {
                    UIViewController* destinationViewController = [navigationController.viewControllers lastObject];
                    [destinationViewController setValue:value forKeyPath:destinationValueKeyPath];
                }
            });
        }
    }
}

- (void)performWithOptions:(NSDictionary*)options destinationViewController:(id)destinationViewController {
    NSArray* keypaths = options[@"keypaths"];
    for (NSDictionary *keypath in keypaths) {
        NSString* sourceValueKeyPath = keypath[@"source"];
        NSString* destinationValueKeyPath = keypath[@"destination"];
        if (sourceValueKeyPath.nonempty && destinationValueKeyPath.nonempty) {
            id value = [self.sourceViewController valueForKeyPath:sourceValueKeyPath];
            if (value) {
                [destinationViewController setValue:value forKeyPath:destinationValueKeyPath];
            }
        }
    }
    
    NSDictionary* attributes = options[@"attributes"];
    [destinationViewController setValuesForKeysWithDictionary:attributes];
    
    NSString* transition = options[@"transition"];
    if ([transition isEqualToString:@"modal"]) {
        [self.sourceViewController presentViewController:destinationViewController animated:YES completion:nil];
    } else if ([transition isEqualToString:@"root"]) {
        [UIWindow mainWindow].rootViewController = destinationViewController;
    } else {
        [[self.sourceViewController navigationController] pushViewController:destinationViewController animated:YES];
    }
}

@end

@implementation WLSwitchStoryboardSegue

- (void)perform {
    if (!self.identifier.nonempty) return;
    if ([self.identifier rangeOfString:@"->"].location != NSNotFound) {
        NSArray* options = [self.identifier componentsSeparatedByString:@"->"];
        if (options.count == 2) {
            NSString* storyboardName = [options objectAtIndex:0];
            NSString* presentation = [options objectAtIndex:1];
            if (storyboardName.nonempty && presentation.nonempty) {
                UIStoryboard* storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
                UIViewController* controller = [storyboard instantiateInitialViewController];
                if ([presentation isEqualToString:@"root"]) {
                    [UIApplication sharedApplication].keyWindow.rootViewController = controller;
                } else if ([presentation isEqualToString:@"modal"]) {
                    [self.sourceViewController presentViewController:controller animated:YES completion:nil];
                }
            }
        }
    } else {
        NSDictionary *options = [NSJSONSerialization JSONObjectWithData:[self.identifier dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
        if (options && options[@"storyboard"]) {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:options[@"storyboard"] bundle:nil];
            [self performWithOptions:options destinationViewController:[storyboard instantiateInitialViewController]];
        } else {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:self.identifier bundle:nil];
            UIViewController* controller = [storyboard instantiateInitialViewController];
            [self.sourceViewController presentViewController:controller animated:YES completion:nil];
        }
    }
}

@end
