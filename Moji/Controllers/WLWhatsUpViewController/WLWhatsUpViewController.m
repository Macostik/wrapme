//
//  WLWhatsUpViewController.m
//  moji
//
//  Created by Ravenpod on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWhatsUpViewController.h"
#import "WLUserView.h"
#import "StreamDataSource.h"
#import "WLNotificationCenter.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLWhatsUpCell.h"
#import "UIFont+CustomFonts.h"
#import "WLComposeBar.h"
#import "WLToast.h"
#import "WLWhatsUpSet.h"
#import "WLWhatsUpEvent.h"

@interface WLWhatsUpViewController () <WLEntryNotifyReceiver>

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;
@property (strong, nonatomic) IBOutlet StreamMetrics *commentMetrics;
@property (strong, nonatomic) IBOutlet StreamMetrics *candyMetrics;

@end

@implementation WLWhatsUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak typeof(self)weakSelf = self;
    
    [self.candyMetrics setSizeBlock:^CGFloat(StreamIndex *index) {
        UIFont *fontNormal = [UIFont preferredDefaultFontWithPreset:WLFontPresetNormal];
        UIFont *fontSmall = [UIFont preferredDefaultFontWithPreset:WLFontPresetSmall];
        return 2*floorf(fontNormal.lineHeight) + floorf(fontSmall.lineHeight) + WLPaddingCell;
    }];
    
    [self.candyMetrics setHiddenBlock:^BOOL(StreamIndex *index) {
        WLWhatsUpEvent *event = [weakSelf.dataSource.items tryAt:index.item];
        return ![event.contribution isKindOfClass:[WLCandy class]];
    }];
    
    [self.commentMetrics setSizeBlock:^CGFloat(StreamIndex *index) {
        WLWhatsUpEvent *event = [weakSelf.dataSource.items tryAt:index.item];
        UIFont *font = [UIFont preferredDefaultFontWithPreset:WLFontPresetNormal];
        CGFloat textHeight = [[event.contribution text] heightWithFont:font width:WLConstants.screenWidth - WLWhatsUpCommentHorizontalSpacing];
        return textHeight + weakSelf.candyMetrics.sizeBlock(index);
    }];
    
    [self.commentMetrics setHiddenBlock:^BOOL(StreamIndex *index) {
        WLWhatsUpEvent *event = [weakSelf.dataSource.items tryAt:index.item];
        return ![event.contribution isKindOfClass:[WLComment class]];
    }];
    
    self.commentMetrics.selectionBlock = self.candyMetrics.selectionBlock = ^(WLWhatsUpEvent *event) {
        [WLChronologicalEntryPresenter presentEntry:event.contribution animated:YES];
    };
 
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
