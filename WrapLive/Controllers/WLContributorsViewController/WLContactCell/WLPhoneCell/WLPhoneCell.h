//
//  WLPhoneCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 09.05.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLItemCell.h"

@class WLPhoneCell;
@class WLPhone;

@protocol WLPhoneCellDelegate <NSObject>

- (void)phoneCell:(WLPhoneCell*)cell didSelectPhone:(WLPhone *)phone;

@end

@interface WLPhoneCell : WLItemCell

@property (nonatomic, weak) IBOutlet id <WLPhoneCellDelegate> delegate;

@property (nonatomic) BOOL checked;

@end
