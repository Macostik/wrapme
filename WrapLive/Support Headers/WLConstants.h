//
//  WLConstants.h
//  WrapLive
//
//  Created by Sergey Maximenko on 1/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

struct WLConstantsStruct {
    CGFloat pixelSize;
    BOOL iPhone;
};

struct WLConstantsStruct WLConstants;

static inline void WLInitializeConstants (void) {
    WLConstants = (struct WLConstantsStruct) {
        .pixelSize = 1.0f / ([UIScreen mainScreen].scale < 2 ? : 2),
        .iPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
    };
}


