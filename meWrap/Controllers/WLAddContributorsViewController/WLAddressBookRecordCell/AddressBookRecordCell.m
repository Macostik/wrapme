//
//  WLrecordCell.m
//  meWrap
//
//  Created by Ravenpod on 09.05.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "AddressBookRecordCell.h"

@interface AddressBookRecordCell ()

@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (nonatomic, weak) IBOutlet StreamView* streamView;
@property (nonatomic, weak) IBOutlet UILabel* nameLabel;
@property (nonatomic, weak) IBOutlet ImageView* avatarView;
@property (weak, nonatomic) IBOutlet UIButton *openView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *pandingLabel;
@property (weak, nonatomic) IBOutlet UIButton *statusButton;
@property (strong, nonatomic) IBOutlet LayoutPrioritizer *statusPrioritizer;
@property (strong, nonatomic) StreamDataSource *dataSource;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;


@end

@implementation AddressBookRecordCell

- (void)awakeFromNib {
    [super awakeFromNib];
    __weak typeof(self)weakSelf = self;
    self.dataSource = [[StreamDataSource alloc] initWithStreamView:self.streamView];
    [self.dataSource addMetrics:[[StreamMetrics alloc] initWithIdentifier:@"AddressBookPhoneNumberCell" initializer:^(StreamMetrics *metrics) {
        metrics.size = 50;
        metrics.selectable = YES;
        [metrics setFinalizeAppearing:^(StreamItem *item, StreamReusableView* view) {
            AddressBookPhoneNumberCell* cell = (id)view;
            AddressBookPhoneNumber *phoneNumber = item.entry;
            cell.checked = [weakSelf.delegate recordCell:weakSelf phoneNumberState:phoneNumber];
        }];
        [metrics setSelection:^(StreamItem *item, AddressBookPhoneNumber *phoneNumber) {
            [weakSelf.delegate recordCell:weakSelf didSelectPhoneNumber:phoneNumber];
        }];
    }]];
}

- (void)setup:(AddressBookRecord *)record {
	AddressBookPhoneNumber* phoneNumber = [record.phoneNumbers lastObject];
    
    User *user = phoneNumber.user;
	self.nameLabel.text = phoneNumber.name;
    NSString *url = phoneNumber.avatar.small;
    if (user && phoneNumber.activated && !url.nonempty) {
        self.avatarView.defaultBackgroundColor = Color.orange;
    } else {
        self.avatarView.defaultBackgroundColor = Color.grayLighter;
    }
    self.avatarView.url = url;
	
	if (self.streamView) {
        [self layoutIfNeeded];
        self.dataSource.items = record.phoneNumbers;
        self.statusLabel.text = @"invite_me_to_meWrap".ls;
	} else {
        self.phoneLabel.text = record.phoneStrings;
        self.pandingLabel.text = user.isInvited ? @"sign_up_pending".ls : @"";
        if (phoneNumber.activated) {
            self.statusLabel.text = @"signup_status".ls;
            
        } else if (user)  {
            self.statusLabel.text = [NSString stringWithFormat:@"invite_status".ls,
                                       [user.invitedAt stringWithDateStyle:NSDateFormatterShortStyle]];
        } else {
            self.statusLabel.text = @"invite_me_to_meWrap".ls;
        }
		self.state = [self.delegate recordCell:self phoneNumberState:phoneNumber];
        self.statusButton.hidden = !(user && (self.state == AddressBookPhoneNumberStateAdded));
        self.statusPrioritizer.defaultState = !(user && (self.state == AddressBookPhoneNumberStateAdded));
	}
}

- (void)setState:(AddressBookPhoneNumberState)state {
	_state = state;
    if (state == AddressBookPhoneNumberStateAdded) {
        self.selectButton.enabled = NO;
    } else {
        self.selectButton.enabled = YES;
        self.selectButton.selected = state == AddressBookPhoneNumberStateSelected;
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
    AddressBookRecord* record = self.entry;
    AddressBookPhoneNumber *person = [record.phoneNumbers lastObject];
	[self.delegate recordCell:self didSelectPhoneNumber:person];
}

- (IBAction)open:(id)sender {
	self.opened = !self.opened;
	[self.delegate recordCellDidToggle:self];
}

@end
