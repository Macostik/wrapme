//
//  WLConstants.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

struct WLConstantsStruct {
    CGFloat pixelSize;
};

struct WLIsIphoneConstantsStruct {
    BOOL iPhone;
};

struct WLConstantsStruct WLConstants;
struct WLIsIphoneConstantsStruct WLiSiPhoneConstants;

static inline void WLInitializeConstants (void) {
    WLConstants = (struct WLConstantsStruct) {
        .pixelSize = 1.0f / [UIScreen mainScreen].scale
    };
    WLiSiPhoneConstants = (struct WLIsIphoneConstantsStruct) {
        .iPhone = [[UIScreen mainScreen] bounds].size.width < 768.0
    };
}


