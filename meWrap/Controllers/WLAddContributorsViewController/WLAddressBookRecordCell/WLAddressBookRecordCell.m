//
//  WLrecordCell.m
//  meWrap
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLAddressBookRecordCell.h"
#import "WLAddressBook.h"
#import "WLAddressBookPhoneNumberCell.h"
#import "WLAddressBookPhoneNumber.h"
#import "UIView+QuartzCoreHelper.h"

@interface WLAddressBookRecordCell () <StreamViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (nonatomic, weak) IBOutlet StreamView* streamView;
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet WLImageView* avatarView;
@property (weak, nonatomic) IBOutlet UIButton *openView;
@property (weak, nonatomic) IBOutlet UILabel *signUpView;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

@implementation WLAddressBookRecordCell

- (void)setup:(WLAddressBookRecord *)record {
	WLAddressBookPhoneNumber* phoneNumber = [record.phoneNumbers lastObject];
    self.signUpView.hidden = (phoneNumber.user && phoneNumber.activated) ? NO : YES;
	self.nameLabel.text = [phoneNumber priorityName];
    NSString *url = phoneNumber.priorityPicture.small;
    if (self.signUpView && !self.signUpView.hidden && !url.nonempty) {
        self.avatarView.defaultBackgroundColor = WLColors.orange;
    } else {
        self.avatarView.defaultBackgroundColor = WLColors.grayLighter;
    }
    self.avatarView.url = url;
	
	if (self.streamView) {
        [self.streamView layoutIfNeeded];
		[self.streamView reload];
	} else {
        self.phoneLabel.text = record.phoneStrings;
		self.state = [self.delegate recordCell:self phoneNumberState:phoneNumber];
	}
}

- (void)setState:(WLAddressBookPhoneNumberState)state {
	_state = state;
    if (state == WLAddressBookPhoneNumberStateAdded) {
        self.selectButton.enabled = NO;
    } else {
        self.selectButton.enabled = YES;
        self.selectButton.selected = state == WLAddressBookPhoneNumberStateSelected;
    }
}

- (void)setOpened:(BOOL)opened {
	_opened = opened;
	[UIView beginAnimations:nil context:nil];
	self.openView.selected = opened;
	[UIView commitAnimations];
}

#pragma mark - Actions

- (IBAction)select:(id)sender {
    WLAddressBookRecord* record = self.entry;
    WLAddressBookPhoneNumber *person = [record.phoneNumbers lastObject];
	[self.delegate recordCell:self didSelectPhoneNumber:person];
}

- (IBAction)open:(id)sender {
	self.opened = !self.opened;
	[self.delegate recordCellDidToggle:self];
}

// MARK: - StreamViewDelegate

- (NSInteger)streamView:(StreamView * __nonnull)streamView numberOfItemsInSection:(NSInteger)section {
	WLAddressBookRecord* record = self.entry;
	return [record.phoneNumbers count];
}

- (void)streamView:(StreamView * __nonnull)streamView didLayoutItem:(StreamItem * __nonnull)item {
    WLAddressBookRecord* record = self.entry;
    item.entry = [record.phoneNumbers tryAt:item.position.index];
}

- (NSArray * __nonnull)streamView:(StreamView * __nonnull)streamView metricsAt:(StreamPosition * __nonnull)position {
    __weak typeof(self)weakSelf = self;
    return @[[[StreamMetrics alloc] initWithIdentifier:@"WLAddressBookPhoneNumberCell" initializer:^(StreamMetrics *metrics) {
        metrics.size = 50;
        [metrics setFinalizeAppearing:^(StreamItem *item, WLAddressBookPhoneNumber* phoneNumber) {
            WLAddressBookPhoneNumberCell* cell = (id)item.view;
            cell.checked = [weakSelf.delegate recordCell:weakSelf phoneNumberState:phoneNumber];
        }];
        [metrics setSelection:^(StreamItem *item, WLAddressBookPhoneNumber *phoneNumber) {
            [weakSelf.delegate recordCell:self didSelectPhoneNumber:phoneNumber];
        }];
    }]];
}

@end
