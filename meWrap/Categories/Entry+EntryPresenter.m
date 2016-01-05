//
//  Entry+EntryPresenter.m
//  meWrap
//
//  Created by Sergey Maximenko on 11/16/15.
//  Copyright © 2015 Ravenpod. All rights reserved.
//

#import "Entry+EntryPresenter.h"
#import "WLWrapViewController.h"
#import "WLCandyViewController.h"
#import "WLChatViewController.h"
#import "WLHistoryViewController.h"

@implementation Candy (WLEntryPresenter)

- (UIViewController *)viewController {
    WLHistoryViewController* controller = (id)[UIStoryboard main][@"WLHistoryViewController"];
    controller.candy = self;
    return controller;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLHistoryViewController class]]) return NO;
    if ([(WLHistoryViewController*)controller candy] != self) return NO;
    return YES;
}

@end

@implementation Message (WLEntryPresenter)

- (UIViewController *)viewController {
    Wrap *wrap = self.wrap;
    if (wrap) {
        WLWrapViewController* controller = (id)[UIStoryboard main][@"WLWrapViewController"];
        controller.wrap = wrap;
        controller.segment = WLWrapSegmentChat;
        return controller;
    }
    return nil;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLWrapViewController class]]) return NO;
    if ([(WLWrapViewController*)controller wrap] != self.wrap) return NO;
    if (([(WLWrapViewController*)controller segment] != WLWrapSegmentChat)) return NO;
    return YES;
}

@end

@implementation Wrap (WLEntryPresenter)

- (UIViewController *)viewController {
    WLWrapViewController* controller = (id)[UIStoryboard main][@"WLWrapViewController"];
    controller.wrap = self;
    return controller;
}

- (BOOL)isValidViewController:(UIViewController *)controller {
    if (![controller isKindOfClass:[WLWrapViewController class]]) return NO;
    if ([(WLWrapViewController*)controller wrap] != self) return NO;
    return YES;
}

@end

@implementation Comment (WLEntryPresenter)

- (void)configureViewController:(UIViewController *)controller fromContainer:(Entry *)container {
    if (container == self.candy) {
        WLHistoryViewController *candyViewController = (WLHistoryViewController *)controller;
        if (candyViewController.isViewLoaded) {
            [candyViewController showCommentView];
        } else {
            candyViewController.showCommentViewController = YES;
        }
    }
}

@end