//
//  WLContribution.m
//  CoreData1
//
//  Created by Ravenpod on 13.06.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLContribution+Extended.h"
#import "WLEntryManager.h"
#import "NSString+Additions.h"
#import "NSDate+Additions.h"
#import "WLAPIRequest.h"
#import "WLNetwork.h"
#import "WLUploading.h"

@implementation WLContribution (Extended)

+ (instancetype)entry:(NSString *)identifier uploadIdentifier:(NSString *)uploadIdentifier {
    return (id)[[WLEntryManager manager] entryOfClass:self identifier:identifier uploadIdentifier:uploadIdentifier];
}

+ (instancetype)API_entry:(NSDictionary *)dictionary container:(id)container {
    NSString *identifier = [self API_identifier:dictionary];
    NSString *uploadIdentifier = [self API_uploadIdentifier:dictionary];
    return [[self entry:identifier uploadIdentifier:uploadIdentifier] API_setup:dictionary container:container];
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

+ (NSOrderedSet *)recentContributions {
    NSMutableArray *contributions = [NSMutableArray array];
    NSDate *date = [[NSDate now] beginOfDay];
    [contributions adds:[WLComment entriesWhere:@"createdAt > %@ AND contributor != nil", date]];
    [contributions adds:[WLCandy entriesWhere:@"createdAt > %@ AND contributor != nil", date]];
    [contributions sortByCreatedAt];
    return [contributions orderedSet];
}

+ (NSOrderedSet *)recentContributions:(NSUInteger)limit {
    NSOrderedSet *contributions = [self recentContributions];
    if (contributions.count > limit) {
        return [NSOrderedSet orderedSetWithArray:[[contributions array] subarrayWithRange:NSMakeRange(0, limit)]];
    }
    return contributions;
}

+ (NSNumber *)uploadingOrder {
    return @5;
}

- (WLContributionStatus)status {
    return [self statusOfUploadingEvent:WLEventAdd];
}

- (WLContributionStatus)statusOfUploadingEvent:(WLEvent)event {
    WLUploading* uploading = self.uploading;
    if (!uploading || uploading.type != event) {
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

+ (void)API_prefetchDescriptors:(NSMutableDictionary *)descriptors inDictionary:(NSDictionary *)dictionary {
    [super API_prefetchDescriptors:descriptors inDictionary:dictionary];
    
    if (dictionary[WLContributorKey]) {
        [WLUser API_prefetchDescriptors:descriptors inDictionary:dictionary[WLContributorKey]];
    }
    
    if (dictionary[WLEditorKey]) {
        [WLUser API_prefetchDescriptors:descriptors inDictionary:dictionary[WLEditorKey]];
    }
}

- (instancetype)API_setup:(NSDictionary *)dictionary container:(id)container {
    
    if (dictionary[WLUploadUIDKey]) {
        NSString* uploadIdentifier = [dictionary stringForKey:WLUploadUIDKey];
        if (!NSStringEqual(self.uploadIdentifier, uploadIdentifier)) self.uploadIdentifier = uploadIdentifier;
    }
    
    if (dictionary[WLContributorKey]) {
        WLUser *contributor = [WLUser API_entry:dictionary[WLContributorKey]];
        if (self.contributor != contributor) self.contributor = contributor;
    } else {
        [self parseContributor:dictionary];
    }
    
    if (dictionary[WLEditorKey]) {
        WLUser *editor = [WLUser API_entry:dictionary[WLEditorKey]];
        if (self.editor != editor) self.editor = editor;
    } else {
        [self parseEditor:dictionary];
    }
    
    NSDate* editedAt = [dictionary timestampDateForKey:WLEditedAtKey];
    if (!NSDateEqual(self.editedAt, editedAt)) self.editedAt = editedAt;
    
    return [super API_setup:dictionary container:container];
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
    [contributor editPicture:[contributor.picture editWithContributorDictionary:dictionary]];
}

- (void)parseEditor:(NSDictionary*)dictionary {
    NSString* identifier = [dictionary stringForKey:WLEditorUIDKey];
    if (!identifier.nonempty) return;
    WLUser* editor = self.editor;
    if (!NSStringEqual(editor.identifier, identifier)) {
        editor = [WLUser entry:identifier];
        self.editor = editor;
    }
}

- (BOOL)canBeUploaded {
    return YES;
}

@end
