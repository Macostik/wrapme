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
    NSString* uploadIdentifier = [dictionary stringForKey:WLUploadUIDKey];
    if (!NSStringEqual(self.uploadIdentifier, uploadIdentifier)) self.uploadIdentifier = uploadIdentifier;
    return [super API_setup:dictionary relatedEntry:relatedEntry];
}

- (void)parseContributor:(NSDictionary*)dictionary {
    NSString* identifier = [dictionary stringForKey:WLContributorUIDKey];
    if (!identifier.nonempty) return;
    WLUser* contributor = self.contributor;
    if (!NSStringEqual(contributor.identifier, identifier)) {
        contributor = [WLUser entry:identifier];
        self.contributor = contributor;
    }
    NSString* name = [dictionary stringForKey:WLContributorNameKey];
    if (!NSStringEqual(contributor.name, name)) contributor.name = name;
    [contributor editPicture:[dictionary stringForKey:WLContributorLargeAvatarKey]
                      medium:[dictionary stringForKey:WLContributorMediumAvatarKey]
                       small:[dictionary stringForKey:WLContributorSmallAvatarKey]];
}

- (BOOL)shouldStartUploadingAutomatically {
    return NO;
}

- (BOOL)canBeUploaded {
    return YES;
}

@end
