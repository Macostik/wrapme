//
//  WLWhatsUpViewController.m
//  meWrap
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
    
    [self.candyMetrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        UIFont *fontNormal = [UIFont preferredDefaultFontWithPreset:WLFontPresetNormal];
        UIFont *fontSmall = [UIFont preferredDefaultFontWithPreset:WLFontPresetSmall];
        return 2*floorf(fontNormal.lineHeight) + floorf(fontSmall.lineHeight) + WLPaddingCell;
    }];
    
    [self.candyMetrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
        WLWhatsUpEvent *event = [weakSelf.dataSource.items tryAt:position.index];
        return ![event.contribution isKindOfClass:[WLCandy class]];
    }];
    
    [self.commentMetrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        WLWhatsUpEvent *event = [weakSelf.dataSource.items tryAt:position.index];
        UIFont *font = [UIFont preferredDefaultFontWithPreset:WLFontPresetNormal];
        CGFloat textHeight = [[event.contribution text] heightWithFont:font width:WLConstants.screenWidth - WLWhatsUpCommentHorizontalSpacing];
        return textHeight + weakSelf.candyMetrics.sizeAt(position, weakSelf.candyMetrics);
    }];
    
    [self.commentMetrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
        WLWhatsUpEvent *event = [weakSelf.dataSource.items tryAt:position.index];
        return ![event.contribution isKindOfClass:[WLComment class]];
    }];
    
    self.commentMetrics.selection = self.candyMetrics.selection = ^(StreamItem *item, WLWhatsUpEvent *event) {
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
