//
//  WLAuthorizationFlow.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAuthorizationFlow.h"
#import "WLProfileInformationViewController.h"
#import "WLNavigation.h"

@interface WLAuthorizationFlow ()

@property (weak, nonatomic) UINavigationController* navigationController;

@end

@implementation WLAuthorizationFlow

- (instancetype)initWithNavigationController:(UINavigationController *)controller {
    self = [super init];
    if (self) {
        self.navigationController = controller;
    }
    return self;
}

- (void)start {
    if (self.registrationNotCompleted) {
        self.navigationController.viewControllers = @[[WLProfileInformationViewController instantiate:[UIStoryboard storyboardNamed:WLSignUpStoryboard]]];
    }
}

@end
