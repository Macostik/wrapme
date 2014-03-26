//
//  WLWrapViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLWrapViewController.h"
#import "WLWrap.h"
#import "WLWrapCandiesCell.h"
#import <AFNetworking/UIImageView+AFNetworking.h>

@interface WLWrapViewController ()

@property (strong, nonatomic) IBOutlet UITableView* tableView;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contributorsLabel;

@end

@implementation WLWrapViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self.coverView setImageWithURL:[NSURL URLWithString:self.wrap.cover]];
	self.nameLabel.text = self.wrap.name;
}

- (IBAction)back:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WLWrapCandiesCell* cell = [tableView dequeueReusableCellWithIdentifier:[WLWrapCandiesCell reuseIdentifier]];
    
    cell.item = self.wrap;
    
    return cell;
}

@end
