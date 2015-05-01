//
//  WLWhatsUpViewController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWhatsUpViewController.h"
#import "WLUserView.h"
#import "WLBasicDataSource.h"
#import "WLNotificationCenter.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLWhatsUpCell.h"
#import "UIFont+CustomFonts.h"
#import "WLComposeBar.h"

@interface WLWhatsUpViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

@end

@implementation WLWhatsUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.dataSource setCellIdentifierForItemBlock:^NSString *(id entry, NSUInteger index) {
        NSString *_identifier = [entry isKindOfClass:[WLComment class]] ? @"WLCommentWhatsUpCell" :
                                                                          @"WLCandyWhatsUpCell";
        return _identifier;
    }];
    
    [self.dataSource setItemSizeBlock:^CGSize(id entry, NSUInteger index) {
        
        CGFloat textHeight  = [WLWhatsUpCell additionalHeightCell:entry];
        
        UIFont *fontNormal = [UIFont preferredFontWithName:WLFontOpenSansRegular
                                                    preset:WLFontPresetNormal];
        UIFont *fontSmall = [UIFont preferredFontWithName:WLFontOpenSansRegular
                                                   preset:WLFontPresetSmall];
        return CGSizeMake(WLConstants.screenWidth, textHeight + 2*floorf(fontNormal.lineHeight) + floorf(fontSmall.lineHeight) + WLPaddingCell);

    }];
    
    [self.dataSource setSelectionBlock:^(WLEntry* entry) {
        [WLChronologicalEntryPresenter presentEntry:entry animated:YES];
    }];
 
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.dataSource.items = [[WLUser currentUser] notifications];
}

- (void)updateNotificaton {
    self.dataSource.items = [[WLUser currentUser] notifications];
}

- (void)removeNotificationEntry:(WLEntry *)entry {
    self.dataSource.items = [[WLUser currentUser] notifications];
}

- (void)notifier:(WLEntryNotifier*)notifier commentAdded:(WLComment*)comment {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier *)notifier candyAdded:(WLCandy *)candy {
    [self updateNotificaton];
}

- (void)notifier:(WLEntryNotifier*)notifier commentDeleted:(WLComment *)comment {
    [self removeNotificationEntry:comment];
}

- (void)notifier:(WLEntryNotifier *)notifier candyDeleted:(WLCandy *)candy {
    [self removeNotificationEntry:candy];
}

- (IBAction)back:(id)sender {
    [[WLEntryManager manager].context processPendingChanges];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
