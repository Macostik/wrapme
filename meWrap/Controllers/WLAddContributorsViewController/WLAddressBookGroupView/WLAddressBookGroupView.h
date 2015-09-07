//
//  WLAddressBookGroupView.h
//  meWrap
//
//  Created by Ravenpod on 2/27/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "StreamReusableView.h"

@class WLArrangedAddressBookGroup;

@interface WLAddressBookGroupView : StreamReusableView

@property (strong, nonatomic) WLArrangedAddressBookGroup *group;

@end
