//
//  WLFontPresetHandler.m
//  WrapLive
//
//  Created by Sergey Maximenko on 12/17/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLFontPresetter.h"

@implementation WLFontPresetter

+ (instancetype)presetter {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)setup {
    [super setup];
    __weak typeof(self)weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIContentSizeCategoryDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [weakSelf broadcast:@selector(presetterDidChangeContentSizeCategory:)];
    }];
}

- (NSString *)contentSizeCategory {
    return [UIApplication sharedApplication].preferredContentSizeCategory;
}

@end
