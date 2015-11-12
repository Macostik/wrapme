//
//  WLWhatsUpViewController.m
//  meWrap
//
//  Created by Ravenpod on 8/20/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWhatsUpViewController.h"
#import "WLUserView.h"
#import "WLNotificationCenter.h"
#import "WLChronologicalEntryPresenter.h"
#import "WLWhatsUpCell.h"
#import "WLComposeBar.h"
#import "WLToast.h"
#import "WLWhatsUpSet.h"
#import "WLWhatsUpEvent.h"

@interface WLWhatsUpViewController () <EntryNotifying, WLWhatsUpSetBroadcastReceiver>

@property (strong, nonatomic) IBOutlet StreamDataSource *dataSource;
@property (strong, nonatomic) IBOutlet StreamMetrics *commentMetrics;
@property (strong, nonatomic) IBOutlet StreamMetrics *candyMetrics;

@property (strong, nonatomic) NSOrderedSet *events;

@end

@implementation WLWhatsUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak typeof(self)weakSelf = self;
    
    [self.candyMetrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        UIFont *fontNormal = [UIFont lightFontNormal];
        UIFont *fontSmall = [UIFont lightFontSmall];
        return 2*floorf(fontNormal.lineHeight) + floorf(fontSmall.lineHeight) + WLPaddingCell;
    }];
    
    [self.candyMetrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
        WLWhatsUpEvent *event = [weakSelf.events tryAt:position.index];
        return ![event.contribution isKindOfClass:[Candy class]];
    }];
    
    [self.commentMetrics setSizeAt:^CGFloat(StreamPosition *position, StreamMetrics *metrics) {
        WLWhatsUpEvent *event = [weakSelf.events tryAt:position.index];
        UIFont *font = [UIFont fontNormal];
        CGFloat textHeight = [[event.contribution text] heightWithFont:font width:WLConstants.screenWidth - WLWhatsUpCommentHorizontalSpacing];
        return textHeight + weakSelf.candyMetrics.sizeAt(position, weakSelf.candyMetrics);
    }];
    
    [self.commentMetrics setHiddenAt:^BOOL(StreamPosition *position, StreamMetrics *metrics) {
        WLWhatsUpEvent *event = [weakSelf.events tryAt:position.index];
        return ![event.contribution isKindOfClass:[Comment class]];
    }];
    
    self.commentMetrics.selection = self.candyMetrics.selection = ^(StreamItem *item, WLWhatsUpEvent *event) {
        [WLChronologicalEntryPresenter presentEntry:event.contribution animated:YES];
    };
 
    [[Wrap notifier] addReceiver:self];
    
    self.events = [[WLWhatsUpSet sharedSet].entries copy];
    [[WLWhatsUpSet sharedSet].broadcaster addReceiver:self];
}

- (void)setEvents:(NSOrderedSet *)events {
    _events = events;
    self.dataSource.items = events;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[WLWhatsUpSet sharedSet] update:nil failure:nil];
}

- (void)notifier:(EntryNotifier*)notifier willDeleteEntry:(Entry *)entry {
    [WLToast showMessageForUnavailableWrap:(Wrap *)entry];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

// MARK: - WLWhatsUpSetBroadcastReceiver

- (void)whatsUpBroadcaster:(WLBroadcaster *)broadcaster updated:(WLWhatsUpSet *)set {
    self.events = [set.entries copy];
}

@end
