//
//  WLTestUserPicker.m
//  meWrap
//
//  Created by Ravenpod on 22.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLTestUserPicker.h"
#import "WLTestUserCell.h"

@interface WLTestUserPicker () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray* authorizations;

@property (strong, nonatomic) void (^selection)(Authorization *authorization);

@end

@implementation WLTestUserPicker

+ (void)showInView:(UIView *)view selection:(void (^)(Authorization *))selection {
	[view addSubview:[[WLTestUserPicker alloc] initWithFrame:view.bounds selection:selection]];
}

- (instancetype)initWithFrame:(CGRect)frame selection:(void (^)(Authorization *))selection {
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) {
		self.backgroundColor = [UIColor whiteColor];
		self.selection = selection;
        self.dataSource = self;
		self.delegate = self;
        self.authorizations = [[Environment currentEnvironment] testUsers];
        [self performSelector:@selector(reloadData) withObject:nil afterDelay:0.0f];
    }
    return self;
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.authorizations count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLTestUserCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WLTestUserCell"];
	if (!cell) cell = [WLTestUserCell loadFromNib:@"WLTestUserCell"];
	cell.authorization = [self.authorizations objectAtIndex:indexPath.row];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 110;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selection) {
		self.selection([self.authorizations objectAtIndex:indexPath.row]);
	}
	[self removeFromSuperview];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 44;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"cancel".ls forState:UIControlStateNormal];
    button.backgroundColor = Color.orange;
    [button addTarget:self action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

@end
