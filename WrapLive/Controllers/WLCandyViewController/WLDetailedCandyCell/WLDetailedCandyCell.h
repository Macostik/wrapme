//
//  WLDetailedCandyCell.h
//  WrapLive
//
//  Created by Sergey Maximenko on 8/11/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryCell.h"
#import "WLClearProgressBar.h"

static NSString* WLDetailedCandyCellIdentifier = @"WLDetailedCandyCell";

@interface WLDetailedCandyCell : WLEntryCell

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet WLClearProgressBar *progressBar;

- (void)refresh;

- (void)updateBottomInset:(CGFloat)bottomInset;

@end
