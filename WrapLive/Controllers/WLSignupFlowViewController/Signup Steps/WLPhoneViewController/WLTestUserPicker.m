//
//  WLTestUserPicker.m
//  WrapLive
//
//  Created by Sergey Maximenko on 22.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLTestUserPicker.h"
#import "NSPropertyListSerialization+Shorthand.h"
#import "WLAuthorization.h"
#import "NSArray+Additions.h"
#import "WLAPIManager.h"
#import "UIColor+CustomColors.h"
#import "WLTestUserCell.h"
#import "NSObject+NibAdditions.h"
#import "WLAPIEnvironment+TestUsers.h"

@interface WLTestUserPicker () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray* groups;

@property (strong, nonatomic) void (^selection)(WLAuthorization* authorization);

@end

@implementation WLTestUserPicker

+ (void)showInView:(UIView *)view selection:(void (^)(WLAuthorization *))selection {
	[view addSubview:[[WLTestUserPicker alloc] initWithFrame:view.bounds selection:selection]];
}

- (instancetype)initWithFrame:(CGRect)frame selection:(void (^)(WLAuthorization *))selection {
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) {
		self.backgroundColor = [UIColor whiteColor];
		self.selection = selection;
        self.dataSource = self;
		self.delegate = self;
        __weak typeof(self)weakSelf = self;
        [[WLAPIManager instance].environment testUsers:^(NSArray *testUsers) {
            weakSelf.groups = testUsers;
            [weakSelf performSelector:@selector(reloadData) withObject:nil afterDelay:0.0f];
        }];
    }
    return self;
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.groups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray* users = [[self.groups objectAtIndex:section] objectForKey:@"users"];
	return [users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	WLTestUserCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WLTestUserCell"];
	if (!cell) cell = [WLTestUserCell loadFromNib];
    NSArray* users = [[self.groups objectAtIndex:indexPath.section] objectForKey:@"users"];
	cell.authorization = [users objectAtIndex:indexPath.row];
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 110;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selection) {
        NSArray* users = [[self.groups objectAtIndex:indexPath.section] objectForKey:@"users"];
		self.selection([users objectAtIndex:indexPath.row]);
	}
	[self removeFromSuperview];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self.groups count] - 1) {
        return 44;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == [self.groups count] - 1) {
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:@"Cancel" forState:UIControlStateNormal];
        button.backgroundColor = [UIColor WL_orangeColor];
        [button addTarget:self action:@selector(removeFromSuperview) forControlEvents:UIControlEventTouchUpInside];
        return button;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.groups objectAtIndex:section] objectForKey:@"name"];
}

@end
