//
//  WLBaseViewController.m
//  meWrap
//
//  Created by Ravenpod on 10/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBaseViewController.h"

@interface WLBaseViewController ()

@property (nonatomic) IBInspectable BOOL statusBarDefault;

@end

@implementation WLBaseViewController

- (void)dealloc {
#ifdef DEBUG
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
#endif
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.preferredViewFrame = [UIWindow mainWindow].bounds;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.preferredViewFrame = [UIWindow mainWindow].bounds;
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.preferredViewFrame = [UIWindow mainWindow].bounds;
    }
    return self;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return !self.statusBarDefault ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (void)loadView {
    [super loadView];
    if ([self shouldUsePreferredViewFrame]) {
        self.view.frame = self.preferredViewFrame;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([self shouldUsePreferredViewFrame]) {
        [self.view layoutIfNeeded];
    }
    self.screenName = NSStringFromClass([self class]);
    self.keyboardAdjustmentAnimated = YES;
    [[Keyboard keyboard] addReceiver:self];
}

- (BOOL)shouldUsePreferredViewFrame {
    return YES;
}

- (NSMapTable *)keyboardAdjustmentDefaultConstants {
    NSMapTable *constants = _keyboardAdjustmentDefaultConstants;
    if (!constants) {
        constants = [NSMapTable strongToStrongObjectsMapTable];
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentTopConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        for (NSLayoutConstraint *constraint in self.keyboardAdjustmentBottomConstraints) {
            [constants setObject:@(constraint.constant) forKey:constraint];
        }
        _keyboardAdjustmentDefaultConstants = constants;
    }
    return constants;
}

static NSString *lastAppearedScreenName = nil;

+ (NSString *)lastAppearedScreenName {
    return lastAppearedScreenName;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.viewAppeared = YES;
    lastAppearedScreenName = [self screenName];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.viewAppeared = NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - KeyboardNotifying

- (NSArray *)keyboardAdjustmentLayoutViews {
    if (!_keyboardAdjustmentLayoutViews.nonempty) {
        _keyboardAdjustmentLayoutViews = @[self.view];
    }
    return _keyboardAdjustmentLayoutViews;
}

@end
