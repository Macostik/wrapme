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
#import "NSDate+Additions.h"
#import "WLAPIRequest.h"
#import "WLNetwork.h"

@implementation WLContribution (Extended)

+ (instancetype)entry:(NSString *)identifier uploadIdentifier:(NSString *)uploadIdentifier {
    return (id)[[WLEntryManager manager] entryOfClass:self identifier:identifier uploadIdentifier:uploadIdentifier];
}

+ (instancetype)API_entry:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    NSString *identifier = [self API_identifier:dictionary];
    NSString *uploadIdentifier = [self API_uploadIdentifier:dictionary];
    return [[self entry:identifier uploadIdentifier:uploadIdentifier] API_setup:dictionary relatedEntry:relatedEntry];
}

+ (NSString *)API_uploadIdentifier:(NSDictionary *)dictionary {
    return [dictionary stringForKey:WLUploadUIDKey];
}

+ (instancetype)contribution {
    WLContribution* contributrion = [self entry];
    contributrion.uploadIdentifier = contributrion.identifier;
    contributrion.contributor = [WLUser currentUser];
    return contributrion;
}

+ (NSMutableOrderedSet *)recentContributions {
    NSMutableOrderedSet *contributions = [NSMutableOrderedSet orderedSet];
    NSDate *date = [[NSDate now] beginOfDay];
    [contributions unionOrderedSet:[WLComment entriesWhere:@"createdAt > %@ AND contributor != nil", date]];
    [contributions unionOrderedSet:[WLCandy entriesWhere:@"createdAt > %@ AND contributor != nil", date]];
    [contributions sortByCreatedAt];
    return contributions;
}

+ (NSNumber *)uploadingOrder {
    return @5;
}

- (WLContributionStatus)status {
    return [self statusOfUploadingType:WLUploadingTypeAdd];
}

- (WLContributionStatus)statusOfUploadingType:(WLUploadingType)type {
    WLUploading* uploading = self.uploading;
    if (!uploading || uploading.type != type) {
        return WLContributionStatusFinished;
    } else if (uploading.data.operation) {
        return WLContributionStatusInProgress;
    } else {
        return WLContributionStatusReady;
    }
}

- (WLContributionStatus)statusOfAnyUploadingType {
    WLUploading* uploading = self.uploading;
    if (!uploading) {
        return WLContributionStatusFinished;
    } else if (uploading.data.operation) {
        return WLContributionStatusInProgress;
    } else {
        return WLContributionStatusReady;
    }
}

- (BOOL)uploaded {
    return self.status == WLContributionStatusFinished;
}

- (BOOL)contributedByCurrentUser {
    return [self.contributor isCurrentUser];
}

- (BOOL)deletable {
    return self.contributedByCurrentUser;
}

- (instancetype)API_setup:(NSDictionary *)dictionary relatedEntry:(id)relatedEntry {
    
    NSString* uploadIdentifier = [dictionary stringForKey:WLUploadUIDKey];
    if (!NSStringEqual(self.uploadIdentifier, uploadIdentifier)) self.uploadIdentifier = uploadIdentifier;
    
    [self parseContributor:dictionary];
    
    [self parseEditor:dictionary];
    
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

- (void)parseEditor:(NSDictionary*)dictionary {
    NSString* identifier = [dictionary stringForKey:WLEditorUIDKey];
    if (!identifier.nonempty) return;
    WLUser* editor = self.editor;
    if (!NSStringEqual(editor.identifier, identifier)) {
        editor = [WLUser entry:identifier];
        self.editor = editor;
    }
    NSDate* editedAt = [dictionary timestampDateForKey:WLEditedAtKey];
    if (!NSDateEqual(self.editedAt, editedAt)) self.editedAt = editedAt;
}

- (BOOL)canBeUploaded {
    return YES;
}

@end
