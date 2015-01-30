//
//  WLCommentsViewController.m
//  
//
//  Created by Yura Granchenko on 28/01/15.
//
//

#import "WLCommentsViewController.h"
#import "WLComposeBar.h"
#import "WLRefresher.h"
#import "WLEntryNotifier.h"
#import "WLAPIManager.h"
#import "WLCommentsViewSection.h"
#import "WLCollectionViewDataProvider.h"
#import "WLCollectionViewFlowLayout.h"
#import "WLSoundPlayer.h"

@interface WLCommentsViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WLCollectionViewDataProvider *dataProvider;
@property (strong, nonatomic) IBOutlet WLCommentsViewSection *dataSection;
@property (nonatomic, readonly) WLCollectionViewFlowLayout* layout;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;
@property (strong, nonatomic) WLRefresher *refresher;

@end

@implementation WLCommentsViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.composeBar.placeholder = @"Write your comment ...";
    self.refresher = [WLRefresher refresher:self.collectionView target:self
                                     action:@selector(refresh:)
                                      style:WLRefresherStyleWhite_Clear];
    NSArray *entries = [[self.candy.comments reverseObjectEnumerator] allObjects];
    self.dataSection.entries = [NSMutableOrderedSet orderedSetWithArray:entries];
    self.collectionView.transform = CGAffineTransformMakeRotation(M_PI);
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)refresh:(WLRefresher*)sender {
    if (self.candy.uploaded) {
        [self.candy fetch:^(id object) {
            [sender setRefreshing:NO animated:YES];
        } failure:^(NSError *error) {
            [error showIgnoringNetworkError];
            [sender setRefreshing:NO animated:YES];
        }];
    } else {
        [sender setRefreshing:NO animated:YES];
    }
}

- (void)sendMessageWithText:(NSString*)text {
    [WLSoundPlayer playSound:WLSound_s04];
    [self.candy uploadComment:text success:^(WLComment *comment) {
    } failure:^(NSError *error) {
    }];
}


- (IBAction)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - WLEntryNotifyReceiver

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment {
    NSArray *entries = [[self.candy.comments reverseObjectEnumerator] allObjects];
    self.dataSection.entries = [NSMutableOrderedSet orderedSetWithArray:entries];
    [self.dataSection reload];
}

- (void)notifier:(WLEntryNotifier*)notifier commentDeleted:(WLComment *)comment {
    NSMutableOrderedSet* entries = self.dataSection.entries.entries;
    if ([entries containsObject:comment]) {
        [entries removeObject:comment];
        [self.dataSection reload];
    }
}

- (WLCandy *)notifierPreferredCandy:(WLEntryNotifier *)notifier {
    return self.candy;
}

#pragma mark - WLComposeBarDelegate

- (void)composeBar:(WLComposeBar *)composeBar didFinishWithText:(NSString *)text {
    [self sendMessageWithText:text];
}

- (BOOL)composeBarDidShouldResignOnFinish:(WLComposeBar *)composeBar {
    return NO;
}

#pragma mark - WLKeyboardBroadcastReceiver

- (CGFloat)keyboardAdjustmentValueWithKeyboardHeight:(CGFloat)keyboardHeight {
    return keyboardHeight - 45.0f;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

@end
