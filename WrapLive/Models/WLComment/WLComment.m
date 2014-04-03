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

+ (NSMutableDictionary *)mapping {
	return [[super mapping] merge:@{@"content":@"text",
									@"comment_uid":@"identifier"}];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError *__autoreleasing *)err
{
    self = [super initWithDictionary:dict error:err];
    if (self) {
        self.author.name = [dict stringForKey:@"contributor_name"];
		self.author.picture = [[WLPicture alloc] initWithDictionary:dict error:NULL];
    }
    return self;
}

+ (instancetype)commentWithText:(NSString *)text {
	WLComment *comment = [WLComment entry];
	comment.text = text;
	return comment;
}

- (WLPicture *)picture {
	return self.author.picture;
}

@end
