//
//  WLPhoneCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLPhoneCell;
@class WLUser;

@protocol WLPhoneCellDelegate <NSObject>

- (void)phoneCell:(WLPhoneCell*)cell didSelectContributor:(WLUser*)contributor;

@end

@interface WLPhoneCell : WLItemCell

@property (nonatomic, weak) IBOutlet id <WLPhoneCellDelegate> delegate;

@property (nonatomic) BOOL checked;

@end
