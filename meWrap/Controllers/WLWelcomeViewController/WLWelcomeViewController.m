//
//  WLViewController.m
//  meWrap
//
//  Created by Ravenpod on 19.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "UIFont+CustomFonts.h"
#import "UIView+GestureRecognizing.h"
#import "WLNavigationHelper.h"
#import "WLSignupFlowViewController.h"
#import "WLWelcomeViewController.h"
#import "WLLayoutPrioritizer.h"

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
@property (strong, nonatomic) IBOutlet WLLayoutPrioritizer *backgroundAnimationPrioritizer;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self underlineLicenseButton];
    
    [self wrapIntoAttributedString];
    __weak typeof(self)weakSelf = self;
    [UITapGestureRecognizer recognizerWithView:self.termsAndConditionsTextView block:^(UIGestureRecognizer *recognizer) {
        [weakSelf flipAnimationView:WLFlipDirectionLeft];
    }];
    
    [weakSelf animateBackgroundView];
}

- (void)animateBackgroundView {
    __weak typeof(self)weakSelf = self;
    NSTimeInterval duration = 30 * (self.backgroundView.height / 1500.0f);
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        weakSelf.backgroundAnimationPrioritizer.defaultState = !weakSelf.backgroundAnimationPrioritizer.defaultState;
    } completion:^(BOOL finished) {
        if (weakSelf.isTopViewController && finished) {
            [weakSelf animateBackgroundView];
        }
    }];
}

- (void)underlineLicenseButton {
	NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:WLLS(@"terms_and_conditions")];
	NSDictionary * attributes = @{NSUnderlineStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle],
								  NSFontAttributeName : [UIFont preferredDefaultFontWithPreset:WLFontPresetSmall],
								  NSForegroundColorAttributeName : WLColors.orange};
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
    run_getting_object(^id{
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Wraplive_TermsAndConditions" withExtension:@"rtf"];
        return [[NSAttributedString alloc] initWithURL:url options:@{} documentAttributes:nil error:nil];
    }, ^(id object) {
        weakSelf.termsAndConditionsTextView.attributedText = object;
    });
}

- (IBAction)agreeAndContinue:(id)sender {
    [self.navigationController setViewControllers:@[[WLSignupFlowViewController instantiate:self.storyboard]] animated:NO];
}

#pragma mark -UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return ![otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]];
}

@end
