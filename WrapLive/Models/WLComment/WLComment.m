//
//  WLComment.m
//  WrapLive
//
//  Created by Sergey Maximenko on 20.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLComment.h"
#import "WLUser.h"

@implementation WLComment

+ (instancetype)commentWithText:(NSString *)text {
	WLComment *comment = [WLComment entry];
	comment.text = text;
	return comment;
}

- (WLPicture *)picture {
	return self.author.picture;
}

@end
