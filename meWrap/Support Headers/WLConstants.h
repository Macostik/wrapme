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

static NSString *const WLAlbumName = @"meWrap";
static NSTimeInterval const maxVideoRecordedDuration = 60;
static NSInteger const WLAddressBookPhoneNumberMinimumLength = 6;
static NSUInteger const WLProfileNameLimit = 40;
static NSUInteger const WLPhoneNumberLimit = 20;
static NSUInteger const WLWrapNameLimit = 190;
static NSInteger const WLHomeTopWrapCandiesLimit = 6;
static NSInteger const WLHomeTopWrapCandiesLimit_2 = 3;
static CGFloat const WLComposeBarDefaultCharactersLimit = 21000;
static NSString *const WLAppGroupEncryptedAuthorization = @"encrypted_authorization";
static NSString *const AppGroupIdentifier = @"group.com.ravenpod.wraplive";

