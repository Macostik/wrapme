//
//  WLEditPicturesViewController.m
//  wrapLive
//
//  Created by Sergey Maximenko on 6/11/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLBatchEditPictureViewController.h"
#import "WLWrapView.h"
#import "WLEditPictureViewController.h"
#import "WLNavigationHelper.h"
#import "WLBasicDataSource.h"
#import "WLComposeBar.h"
#import "AdobeUXImageEditorViewController+SharedEditing.h"
#import "WLEditPictureCell.h"
#import "WLToast.h"

@interface WLBatchEditPictureViewController () <WLComposeBarDelegate>

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

@property (weak, nonatomic) WLEditPicture *picture;

@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;

@end

@implementation WLBatchEditPictureViewController

@synthesize wrap = _wrap;

@synthesize delegate = _delegate;

@synthesize wrapView = _wrapView;

@synthesize mode = _mode;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.dataSource.collectionView.superview addGestureRecognizer:self.dataSource.collectionView.panGestureRecognizer];
    
    [self setupWrapView:self.wrap];
    [self setViewController:[self editPictureViewControllerForPicture:self.pictures.firstObject] direction:0 animated:NO];
    
    self.dataSource.items = self.pictures;
    
    __weak typeof(self)weakSelf = self;
    [self.dataSource setSelectionBlock:^(WLEditPicture *picture) {
        [weakSelf setViewController:[weakSelf editPictureViewControllerForPicture:picture] direction:0 animated:NO];
    }];
    
    self.composeBar.showsDoneButtonOnEditing = YES;
}

- (void)setPicture:(WLEditPicture *)picture {
    _picture = picture;
    [self updatePictureData:picture];
}

- (void)updatePictureData:(WLEditPicture*)picture {
    if (picture.deleted) {
        self.deleteButton.hidden = self.editButton.hidden = self.composeBar.hidden = YES;
        self.restoreButton.hidden = NO;
        if (self.composeBar.isFirstResponder) {
            [self.composeBar resignFirstResponder];
        }
    } else {
        self.deleteButton.hidden = self.editButton.hidden = self.composeBar.hidden = NO;
        self.restoreButton.hidden = YES;
        self.composeBar.text = picture.comment;
    }
    for (WLEditPicture *picture in self.pictures) {
        picture.selected = picture == self.picture;
    }
    [self.dataSource reload];
    NSUInteger index = [self.pictures indexOfObject:self.picture];
    if (index != NSNotFound) {
        __weak typeof(self)weakSelf = self;
        run_after_asap(^{
            [weakSelf.dataSource.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        });
    }
}

// MARK: - WLStillPictureBaseViewController

- (void)setWrap:(WLWrap *)wrap {
    _wrap = wrap;
    if (self.isViewLoaded) {
        [self setupWrapView:wrap];
    }
}

- (void)setupWrapView:(WLWrap *)wrap {
    if (self.wrapView) {
        self.wrapView.entry = wrap;
        self.wrapView.hidden = wrap == nil;
    }
}

- (void)stillPictureViewController:(WLStillPictureBaseViewController *)controller didSelectWrap:(WLWrap *)wrap {
    [self selectWrap:nil];
}

- (IBAction)selectWrap:(UIButton *)sender {
    if (self.delegate) {
        if ([self.delegate respondsToSelector:@selector(stillPictureViewController:didSelectWrap:)]) {
            [self.delegate stillPictureViewController:self didSelectWrap:self.wrap];
        }
    } else if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (WLEditPictureViewController *)editPictureViewControllerForPicture:(WLEditPicture*)picture {
    WLEditPictureViewController *editPictureViewController = [WLEditPictureViewController instantiate:self.storyboard];
    editPictureViewController.picture = picture;
    return editPictureViewController;
}

// MARK: - WLSwipeViewController

- (UIViewController *)viewControllerAfterViewController:(WLEditPictureViewController *)viewController {
    WLEditPicture *picture = [self.pictures tryObjectAtIndex:[self.pictures indexOfObject:viewController.picture] + 1];
    if (picture) {
        return [self editPictureViewControllerForPicture:picture];
    }
    return nil;
}

- (UIViewController *)viewControllerBeforeViewController:(WLEditPictureViewController *)viewController {
    WLEditPicture *picture = [self.pictures tryObjectAtIndex:[self.pictures indexOfObject:viewController.picture] - 1];
    if (picture) {
        return [self editPictureViewControllerForPicture:picture];
    }
    return nil;
}

- (void)didChangeViewController:(WLEditPictureViewController *)viewController {
    self.picture = viewController.picture;
}

// MARK: - Actions

- (IBAction)upload:(id)sender {
    NSArray *pictures = [self.pictures selectObjects:^BOOL(WLEditPicture *picture) {
        return ![picture deleted];
    }];
    if (pictures.nonempty) {
        [self.delegate batchEditPictureViewController:self didFinishWithPictures:pictures];
    } else {
        [WLToast showWithMessage:WLLS(@"no_photos_to_upload")];
    }
}

- (IBAction)edit:(id)sender {
    __weak typeof(self)weakSelf = self;
    UIImage *image = [(WLEditPictureViewController*)self.viewController imageView].image;
    AdobeUXImageEditorViewController* aviaryController = [AdobeUXImageEditorViewController editControllerWithImage:image completion:^(UIImage *image, AdobeUXImageEditorViewController *controller) {
        [weakSelf.picture setImage:image completion:^(id object) {
            weakSelf.picture.edited = YES;
            [weakSelf.dataSource reload];
        }];
        [(WLEditPictureViewController*)weakSelf.viewController imageView].image = image;
        [weakSelf.navigationController popViewControllerAnimated:NO];
    } cancel:^(AdobeUXImageEditorViewController *controller) {
        [weakSelf.navigationController popViewControllerAnimated:NO];
    }];
    [self.navigationController pushViewController:aviaryController animated:NO];
}

- (IBAction)deletePicture:(id)sender {
    self.picture.deleted = YES;
    [(WLEditPictureViewController*)self.viewController updateDeletionState];
    [self updatePictureData:self.picture];
}

- (IBAction)restoreDeletedPicture:(id)sender {
    self.picture.deleted = NO;
    [(WLEditPictureViewController*)self.viewController updateDeletionState];
    [self updatePictureData:self.picture];
}

// MARK: - WLComposeBarDelegate

- (IBAction)composeBarDidFinish:(id)sender {
    [self.composeBar resignFirstResponder];
}

- (void)composeBarDidChangeText:(WLComposeBar *)composeBar {
    self.picture.comment = composeBar.text;
    [self.dataSource reload];
}

- (CGFloat)constantForKeyboardAdjustmentBottomConstraint:(NSLayoutConstraint *)constraint defaultConstant:(CGFloat)defaultConstant keyboardHeight:(CGFloat)keyboardHeight {
    return (keyboardHeight - self.bottomView.height);
}

@end
