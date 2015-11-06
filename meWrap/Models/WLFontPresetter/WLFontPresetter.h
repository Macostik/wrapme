//
//  WLFontPresetHandler.h
//  meWrap
//
//  Created by Ravenpod on 12/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLBroadcaster.h"

@class WLFontPresetter;

@protocol WLFontPresetterReceiver <NSObject>

- (void)presetterDidChangeContentSizeCategory:(WLFontPresetter*)presetter;

@end

@interface WLFontPresetter : WLBroadcaster

@property (readonly, nonatomic) NSString* contentSizeCategory;

+ (instancetype)defaultPresetter;

@end
