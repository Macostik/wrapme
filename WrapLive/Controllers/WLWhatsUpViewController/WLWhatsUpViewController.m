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
        [WLChronologicalEntryPresenter presentEntry:entry animated:NO];
    }];
 
    [[WLComment notifier] addReceiver:self];
    [[WLCandy notifier] addReceiver:self];
    [[WLWrap notifier] addReceiver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[WLEntryManager manager] instantSave];
    [self updateNotificaton];
}

- (void)updateNotificaton {
    self.dataSource.items = [[WLUser currentUser] notifications];
}

- (void)notifier:(WLEntryNotifier*)notifier entryAdded:(WLComment*)comment {
    [self performSelector:@selector(updateNotificaton) withObject:nil afterDelay:0.0];
}

- (void)notifier:(WLEntryNotifier*)notifier entryDeleted:(WLComment *)comment {
    [self performSelector:@selector(updateNotificaton) withObject:nil afterDelay:0.0];
}

- (void)notifier:(WLEntryNotifier *)notifier entryUpdated:(WLEntry *)entry {
    [self performSelector:@selector(updateNotificaton) withObject:nil afterDelay:0.0];
}

- (IBAction)back:(id)sender {
    [[WLEntryManager manager] instantSave];
    [self.navigationController popViewControllerAnimated:NO];
}

@end
