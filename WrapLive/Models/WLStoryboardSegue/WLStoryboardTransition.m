//
//  WLStoryboardTransition.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/12/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLStoryboardTransition.h"
#import "WLNavigationHelper.h"
#import "WLWhatsUpViewController.h"

@implementation WLStoryboardTransition

- (UIViewController*)destinationViewController {
    id destinationViewController = nil;
    if (self.destinationID) {
        UIStoryboard *storyboard = nil;
        if (self.storyboard) {
            storyboard = [UIStoryboard storyboardNamed:self.storyboard];
        } else {
            storyboard = self.sourceViewController.storyboard;
        }
        destinationViewController = [storyboard instantiateViewControllerWithIdentifier:self.destinationID];
    } else if (self.storyboard) {
        destinationViewController = [[UIStoryboard storyboardNamed:self.storyboard] instantiateInitialViewController];
    }
    if (destinationViewController) {
        if (self.sourceValue && self.destinationValue) {
            [destinationViewController setValue:[self.sourceViewController valueForKeyPath:self.sourceValue] forKeyPath:self.destinationValue];
        }
        if (self.sourceIsDelegate && [destinationViewController respondsToSelector:@selector(setDelegate:)]) {
            [destinationViewController setDelegate:(id)self.sourceViewController];
        }
    }
    
    return destinationViewController;
}

- (IBAction)push:(id)sender {
    if (self.sourceViewController) {
        UIViewController *destinationViewController = [self destinationViewController];
        if (destinationViewController) {
            BOOL animated = [destinationViewController isKindOfClass:[WLWhatsUpViewController class]];
            [self.sourceViewController.navigationController pushViewController:destinationViewController animated:animated];
        }
    }
}

- (IBAction)pop:(id)sender {
    if (self.sourceViewController) {
        [self.sourceViewController.navigationController popViewControllerAnimated:NO];
    }
}

- (IBAction)present:(id)sender {
    if (self.sourceViewController) {
        UIViewController *destinationViewController = [self destinationViewController];
        if (destinationViewController) {
            [self.sourceViewController presentViewController:destinationViewController animated:NO completion:nil];
        }
    }
}

@end
