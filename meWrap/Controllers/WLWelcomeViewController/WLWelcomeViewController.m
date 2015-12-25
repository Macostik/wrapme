//
//  WLViewController.m
//  meWrap
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLSignupFlowViewController.h"
#import "WLWelcomeViewController.h"

typedef enum : NSUInteger {
    WLFlipDirectionLeft,
    WLFlipDirectionRight,
} WLFlipDirection;

@interface WLWelcomeViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *licenseButton;
@property (strong, nonatomic) IBOutlet UIView *transparentView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;
@property (strong, nonatomic) IBOutlet UIView *placeholderView;
@property (weak, nonatomic) IBOutlet UITextView *termsAndConditionsTextView;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *backgroundAnimationPrioritizer;

@property (nonatomic) BOOL animating;

@end

@implementation WLWelcomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self underlineLicenseButton];
    
    [self wrapIntoAttributedString];
    __weak typeof(self)weakSelf = self;
    [[[UITapGestureRecognizer alloc] initWithView:self.termsAndConditionsTextView] setActionClosure:^(UIGestureRecognizer *sender) {
        [weakSelf flipAnimationView:WLFlipDirectionLeft];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.animating) {
        self.animating = YES;
    }
}

- (void)underlineLicenseButton {
	NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:@"terms_and_conditions".ls];
	NSDictionary * attributes = @{NSUnderlineStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle],
								  NSFontAttributeName : [UIFont fontSmall],
								  NSForegroundColorAttributeName : [UIColor whiteColor]};
	[titleString addAttributes:attributes range:NSMakeRange(0, [titleString length])];
	[self.licenseButton setAttributedTitle: titleString forState:UIControlStateNormal];
}

- (IBAction)termsAndConditions:(id)sender {
    [self flipAnimationView:WLFlipDirectionRight];
}

- (void)flipAnimationView:(WLFlipDirection)direction {
    UIView *fromView = direction == WLFlipDirectionLeft ? self.placeholderView : self.transparentView;
    UIView *toView = direction ==   WLFlipDirectionLeft ? self.transparentView : self.placeholderView;
    NSInteger option = direction == WLFlipDirectionLeft? UIViewAnimationOptionTransitionFlipFromRight :
                                                         UIViewAnimationOptionTransitionFlipFromLeft;
    
    [UIView transitionFromView:fromView
                        toView:toView
                      duration:0.75
                       options:option | UIViewAnimationOptionShowHideTransitionViews
                    completion:nil];
}

- (void)wrapIntoAttributedString {
    __weak typeof(self)weakSelf = self;
    [[Dispatch defaultQueue] fetch:^id _Nullable{
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Wraplive_TermsAndConditions" withExtension:@"rtf"];
        return [[NSMutableAttributedString alloc] initWithURL:url options:@{} documentAttributes:nil error:nil];
    } completion:^(id object) {
        NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
        [object addAttributes:attributes range:NSMakeRange(0, [object length])];
        weakSelf.termsAndConditionsTextView.attributedText = object;
    }];
}

- (IBAction)agreeAndContinue:(id)sender {
    UIViewController *introduction = [[UIStoryboard introduction] instantiateInitialViewController];
    [self.navigationController setViewControllers:@[introduction] animated:YES];
}

#pragma mark -UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

@end
