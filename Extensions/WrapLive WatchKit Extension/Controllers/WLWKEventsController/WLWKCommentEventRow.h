//
//  WLWKCommentRowType.h
//  WrapLive
//
//  Created by Sergey Maximenko on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKEntryRow.h"

@interface WLWKCommentEventRow : WLWKEntryRow

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *comment;
@property (strong, nonatomic) IBOutlet WKInterfaceImage *icon;

@end
