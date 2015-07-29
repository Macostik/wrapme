//
//  WLViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 19.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIFont+CustomFonts.h"
#import "UIView+GestureRecognizing.h"
#import "WLLoadingView.h"
#import "WLNavigationHelper.h"
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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundTopConstraint;

@end

@implementation WLWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self underlineLicenseButton];
    
    [self animateBackgroundView:-(self.backgroundView.height - self.view.height + 20) nextOffset:-20];
    
    [self wrapIntoAttributedString];
    __weak typeof(self)weakSelf = self;
    [UITapGestureRecognizer recognizerWithView:self.termsAndConditionsTextView block:^(UIGestureRecognizer *recognizer) {
        [weakSelf flipAnimationView:WLFlipDirectionLeft];
    }];
}

- (void)animateBackgroundView:(CGFloat)offset nextOffset:(CGFloat)nextOffset {
    __weak typeof(self)weakSelf = self;
    weakSelf.backgroundTopConstraint.constant = offset;
    [UIView animateWithDuration:30 * (self.backgroundView.height / 1500.0f) delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^{
        [weakSelf.backgroundView layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (weakSelf.isTopViewController) {
            [weakSelf animateBackgroundView:nextOffset nextOffset:offset];
        }
    }];
}

- (void)underlineLicenseButton {
	NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:WLLS(@"Terms and Conditions")];
	NSDictionary * attributes = @{NSUnderlineStyleAttributeName : [NSNumber numberWithInteger:NSUnderlineStyleSingle],
								  NSFontAttributeName : [UIFont fontWithName:WLDefaultSystemFont preset:WLFontPresetSmall],
								  NSForegroundColorAttributeName : [UIColor WL_orange]};
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
        return [[NSAttributedString alloc] initWithFileURL:url options:nil documentAttributes:nil error:nil];
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
