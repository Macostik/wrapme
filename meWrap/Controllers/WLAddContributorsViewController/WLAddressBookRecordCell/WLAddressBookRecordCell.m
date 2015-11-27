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
#import "WLImageView.h"

@interface WLAddressBookRecordCell ()

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (nonatomic, weak) IBOutlet StreamView* streamView;
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet WLImageView* avatarView;
@property (weak, nonatomic) IBOutlet UIButton *openView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *statusPrioritizer;
@property (strong, nonatomic) StreamDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;


@end

@implementation WLAddressBookRecordCell

- (void)awakeFromNib {
    [super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    self.dataSource = [[StreamDataSource alloc] initWithStreamView:self.streamView];
    [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"WLAddressBookPhoneNumberCell" initializer:^(StreamMetrics *metrics) {
        metrics.size = 50;
        metrics.selectable = YES;
        [metrics setFinalizeAppearing:^(StreamItem *item, WLAddressBookPhoneNumber* phoneNumber) {
            WLAddressBookPhoneNumberCell* cell = (id)item.view;
            cell.checked = [weakSelf.delegate recordCell:weakSelf phoneNumberState:phoneNumber];
        }];
        [metrics setSelection:^(StreamItem *item, WLAddressBookPhoneNumber *phoneNumber) {
            [weakSelf.delegate recordCell:weakSelf didSelectPhoneNumber:phoneNumber];
        }];
    }]];
}

- (void)setup:(WLAddressBookRecord *)record {
	WLAddressBookPhoneNumber* phoneNumber = [record.phoneNumbers lastObject];
    
	self.nameLabel.text = phoneNumber.name;
    NSString *url = phoneNumber.picture.small;
    if (phoneNumber.user && phoneNumber.activated && !url.nonempty) {
        self.avatarView.defaultBackgroundColor = WLColors.orange;
    } else {
        self.avatarView.defaultBackgroundColor = WLColors.grayLighter;
    }
    self.avatarView.url = url;
	
	if (self.streamView) {
        [self layoutIfNeeded];
        self.dataSource.items = record.phoneNumbers;
	} else {
        self.phoneLabel.text = record.phoneStrings;
        if (phoneNumber.activated) {
            self.statusLabel.text = @"signup_status".ls;
        } else if (phoneNumber.user)  {
            self.statusLabel.text = [NSString stringWithFormat:@"invite_status".ls,
                                       [phoneNumber.user.invitedAt stringWithDateStyle:NSDateFormatterShortStyle]];
        } else {
            self.statusLabel.text = @"";
        }
		self.state = [self.delegate recordCell:self phoneNumberState:phoneNumber];
        self.statusButton.hidden = !phoneNumber.user;
        self.statusButton.enabled = phoneNumber.activated;
        self.statusPrioritizer.defaultState = self.state == WLAddressBookPhoneNumberStateDefault;
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

@end
