//
//  WLConstants.h
//  meWrap
//
//  Created by Ravenpod on 1/6/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

typedef struct {
    CGFloat pixelSize;
    CGFloat screenWidth;
    BOOL iPhone;
    NSUInteger appStoreID;
} WLConstantsStruct;

WLConstantsStruct WLConstants;

__attribute__((constructor))
static void WLInitializeConstants (void) {
    WLConstants = (WLConstantsStruct) {
        .pixelSize = 1.0f / ([UIScreen mainScreen].scale < 2 ? : 2),
        .screenWidth = [UIScreen mainScreen].bounds.size.width,
        .iPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone,
        .appStoreID = 879908578,
    };
}

static NSString *WLAlbumName = @"meWrap";
static NSTimeInterval maxVideoRecordedDuration = 60;


