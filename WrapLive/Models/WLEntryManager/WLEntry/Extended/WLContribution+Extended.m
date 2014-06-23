//
//  WLContribution.m
//  CoreData1
//
//  Created by Sergey Maximenko on 13.06.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "WLContribution+Extended.h"
#import "WLEntryManager.h"
#import "NSString+Additions.h"

@implementation WLContribution (Extended)

+ (instancetype)contribution {
    WLContribution* contributrion = [self entry];
    contributrion.uploadIdentifier = contributrion.identifier;
    contributrion.contributor = [WLUser currentUser];
    return contributrion;
}

+ (NSNumber *)uploadingOrder {
    return @5;
}

- (BOOL)uploaded {
    return self.uploading == nil;
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    [self parseContributor:dictionary];
    self.uploadIdentifier = [dictionary stringForKey:@"upload_uid"];
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (void)parseContributor:(NSDictionary*)dictionary {
    NSString* identifier = [dictionary stringForKey:@"contributor_uid"];
    WLUser* contributor = self.contributor;
    if (![contributor.identifier isEqualToString:identifier]) {
        contributor = [WLUser entry:[dictionary stringForKey:@"contributor_uid"] create:YES];
        self.contributor = contributor;
    }
    contributor.name = [dictionary stringForKey:@"contributor_name"];
	WLPicture* picture = [[WLPicture alloc] init];
	picture.large = [dictionary stringForKey:@"contributor_large_avatar_url"];
	picture.medium = [dictionary stringForKey:@"contributor_medium_avatar_url"];
	picture.small = [dictionary stringForKey:@"contributor_small_avatar_url"];
	contributor.picture = picture;
}

- (BOOL)shouldStartUploadingAutomatically {
    return NO;
}

- (BOOL)canBeUploaded {
    return YES;
}

@end
