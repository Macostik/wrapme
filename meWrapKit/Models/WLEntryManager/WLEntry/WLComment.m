//
//  WLComment.m
//  meWrap
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLComment.h"
#import "WLCandy.h"


@implementation WLComment

@dynamic text;
@dynamic candy;

- (BOOL)deletable {
    return self.contributedByCurrentUser || self.candy.deletable;
}

- (BOOL)canBeUploaded {
    return self.candy.uploaded && self.uploading;
}

- (WLAsset *)picture {
    return self.candy.picture;
}

@end
