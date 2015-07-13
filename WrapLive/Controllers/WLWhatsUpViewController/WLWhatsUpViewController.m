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
#import "WLToast.h"
#import "WLWhatsUpSet.h"
#import "WLWhatsUpEvent.h"

@interface WLWhatsUpViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet WLBasicDataSource *dataSource;

@end

@implementation WLWhatsUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.dataSource setCellIdentifierForItemBlock:^NSString *(WLWhatsUpEvent *event, NSUInteger index) {
        return [event.contribution isKindOfClass:[WLComment class]] ? @"WLCommentWhatsUpCell" : @"WLCandyWhatsUpCell";
    }];
    
    [self.dataSource setItemSizeBlock:^CGSize(WLWhatsUpEvent *event, NSUInteger index) {
        
        CGFloat textHeight  = [WLWhatsUpCell additionalHeightCell:event];
        
        UIFont *fontNormal = [UIFont preferredFontWithName:WLFontOpenSansLight
                                                    preset:WLFontPresetNormal];
        UIFont *fontSmall = [UIFont preferredFontWithName:WLFontOpenSansLight
                                                   preset:WLFontPresetSmall];
        return CGSizeMake(WLConstants.screenWidth, textHeight + 2*floorf(fontNormal.lineHeight) + floorf(fontSmall.lineHeight) + WLPaddingCell);

    }];
    
    [self.dataSource setSelectionBlock:^(WLWhatsUpEvent *event) {
        [WLChronologicalEntryPresenter presentEntry:event.contribution animated:YES];
    }];
 
    [[WLWrap notifier] addReceiver:self];
    
    self.dataSource.items = [WLWhatsUpSet sharedSet];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [(WLWhatsUpSet*)self.dataSource.items update:nil failure:nil];
}

- (void)notifier:(WLEntryNotifier*)notifier willDeleteEntry:(WLEntry *)entry {
    [WLToast showMessageForUnavailableWrap:(WLWrap*)entry];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

@end
