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

@interface WLTestUserPicker () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSArray* users;

@property (strong, nonatomic) void (^selection)(WLAuthorization* authorization);

@end

@implementation WLTestUserPicker

+ (void)showInView:(UIView *)view selection:(void (^)(WLAuthorization *))selection {
	[view addSubview:[[WLTestUserPicker alloc] initWithFrame:view.bounds selection:selection]];
}

- (instancetype)initWithFrame:(CGRect)frame selection:(void (^)(WLAuthorization *))selection {
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) {
		self.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.75f];
		self.selection = selection;
        self.dataSource = self;
		self.delegate = self;
		self.users = [[NSArray resourcePropertyListNamed:@"WLTestUsers"] map:^id(id item) {
            WLAuthorization* authorization = [[WLAuthorization alloc] init];
            authorization.deviceUID = [item objectForKey:@"deviceUID"];
            authorization.countryCode = [item objectForKey:@"countryCode"];
            authorization.phone = [item objectForKey:@"phone"];
            authorization.email = [item objectForKey:@"email"];
            authorization.activationCode = [item objectForKey:@"activationCode"];
            authorization.password = [item objectForKey:@"password"];
            return authorization;
        }];
		[self performSelector:@selector(reloadData) withObject:nil afterDelay:0.0f];
    }
    return self;
}

#pragma mark - <UITableViewDataSource, UITableViewDelegate>

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"WLTestUserPickerCell"];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"WLTestUserPickerCell"];
	}
	WLAuthorization* authorization = [self.users objectAtIndex:indexPath.row];
	cell.textLabel.text = [authorization fullPhoneNumber];
	cell.detailTextLabel.text = authorization.password ? @"Activated" : @"Non-activated";
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.selection) {
		self.selection([self.users objectAtIndex:indexPath.row]);
	}
	[self removeFromSuperview];
}

@end
