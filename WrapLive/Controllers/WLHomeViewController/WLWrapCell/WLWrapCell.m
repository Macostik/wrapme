//
//  WLWrapCell.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "NSObject+NibAdditions.h"
#import "UIActionSheet+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "UILabel+Additions.h"
#import "UIView+GestureRecognizing.h"
#import "UIView+Shorthand.h"
#import "WLAPIManager.h"
#import "WLCandyCell.h"
#import "WLCollectionViewDataProvider.h"
#import "WLEntryManager.h"
#import "WLEntryNotifier.h"
#import "WLHomeCandiesViewSection.h"
#import "WLImageFetcher.h"
#import "WLNotification.h"
#import "WLNotificationCenter.h"
#import "WLBadgeLabel.h"
#import "WLWrapCell.h"
#import "TTTAttributedLabel.h"
#import "UIFont+CustomFonts.h"

@interface WLWrapCell ()

@property (weak, nonatomic) IBOutlet WLImageView *coverView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *candiesView;
@property (weak, nonatomic) IBOutlet WLBadgeLabel *wrapNotificationLabel;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (assign, nonatomic) BOOL embeddedLongPress;

@property (strong, nonatomic) WLCollectionViewDataProvider* candiesDataProvider;
@property (strong, nonatomic) WLHomeCandiesViewSection* candiesDataSection;

@end

@implementation WLWrapCell

- (void)awakeFromNib {
	[super awakeFromNib];
    
    if (self.candiesView) {
        UICollectionViewFlowLayout* layout = (id)self.candiesView.collectionViewLayout;
        layout.minimumLineSpacing = WLCandyCellSpacing;
        layout.sectionInset = UIEdgeInsetsMake(0, WLCandyCellSpacing, 0, WLCandyCellSpacing);
        
        WLHomeCandiesViewSection* section = [[WLHomeCandiesViewSection alloc] initWithCollectionView:self.candiesView];
        section.reuseCellIdentifier = WLCandyCellIdentifier;
        section.selection = self.selection;
        self.candiesDataSection = section;
        self.candiesDataProvider = [WLCollectionViewDataProvider dataProvider:self.candiesView section:section];
    }
    [self.coverView setImageName:@"default-small-cover" forState:WLImageViewStateEmpty];
    [self.coverView setImageName:@"default-small-cover" forState:WLImageViewStateFailed];
    
    __weak __typeof(self)weakSelf = self;
    [UILongPressGestureRecognizer recognizerWithView:self block:^(UIGestureRecognizer *recognizer) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            if  ([weakSelf.delegate respondsToSelector:@selector(wrapCell:didDeleteWrap:)])
                [weakSelf.delegate wrapCell:weakSelf didDeleteWrap:weakSelf.entry];
        }
    }];
}

- (void)setSelection:(WLObjectBlock)selection {
    [super setSelection:selection];
    self.candiesDataSection.selection = selection;
}

- (void)setup:(WLWrap*)wrap {
	self.nameLabel.text = wrap.name;
    self.dateLabel.text = WLString(wrap.updatedAt.timeAgoStringAtAMPM);
    
    if (self.candiesView) {
        self.candiesDataSection.entries = [wrap recentCandies:WLHomeTopWrapCandiesLimit];
    }
    
    self.coverView.url = [wrap.picture anyUrl];
    self.wrapNotificationLabel.intValue = [wrap unreadNotificationsCandyCount];
    self.chatButton.hidden = [wrap unreadNotificationsMessageCount] == 0;
}

- (IBAction)notifyChatClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(wrapCell:forWrap:notifyChatButtonClicked:)])
        [self.delegate wrapCell:self forWrap:self.entry notifyChatButtonClicked:sender];
}

@end