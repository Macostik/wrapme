//
//  WLCommentsViewController.m
//  
//
//  Created by Yura Granchenko on 28/01/15.
//
//

#import "WLCommentsViewController.h"
#import "WLComposeBar.h"

@interface WLCommentsViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet WLComposeBar *composeBar;

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
}

- (IBAction)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
