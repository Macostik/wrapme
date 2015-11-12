//
//  InterfaceController.m
//  meWrap-Development WatchKit Extension
//
//  Created by Ravenpod on 12/26/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLWKContributionsController.h"
#import "WLWKEntryRow.h"

typedef NS_ENUM(NSUInteger, WLWKContributionsState) {
    WLWKContributionsStateDefault,
    WLWKContributionsStateEmpty,
    WLWKContributionsStateError
};

@interface WLWKContributionsController()

@property (strong, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) NSArray* entries;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *errorGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *errorLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *placeholderGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *noUpdatesLabel;

@property (nonatomic) WLWKContributionsState state;

@end


@implementation WLWKContributionsController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    [self.noUpdatesLabel setText:@"no_recent_updates".ls];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseUpdated) name:@"dataSync" object:nil];
}

- (void)databaseUpdated {
    [self updateContributions];
}

- (void)setState:(WLWKContributionsState)state {
    _state = state;
    switch (state) {
        case WLWKContributionsStateEmpty:
            [self.table setHidden:YES];
            [self.errorGroup setHidden:YES];
            [self.placeholderGroup setHidden:NO];
            break;
        case WLWKContributionsStateError:
            [self.table setHidden:YES];
            [self.errorGroup setHidden:NO];
            [self.placeholderGroup setHidden:YES];
            break;
        default:
            [self.table setHidden:NO];
            [self.errorGroup setHidden:YES];
            [self.placeholderGroup setHidden:YES];
            break;
    }
}

- (void)setEntries:(NSArray *)entries {
    _entries = entries;
    
    NSMutableArray *rowTypes = [NSMutableArray array];
    for (Entry *entry in entries) {
        [rowTypes addObject:[[entry class] entityName]];
    }
    
    if (rowTypes.nonempty) {
        self.state = WLWKContributionsStateDefault;
    } else {
        self.state = WLWKContributionsStateEmpty;
    }
    
    [self.table setRowTypes:rowTypes];
    
    for (Entry *entry in entries) {
        [EntryContext.sharedContext refreshObject:entry mergeChanges:NO];
        NSUInteger index = [entries indexOfObject:entry];
        WLWKEntryRow* row = [self.table rowControllerAtIndex:index];
        [row setEntry:entry];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    Entry *entry = self.entries[rowIndex];
    if (entry.valid) {
        if ([entry isKindOfClass:[Comment class]]) {
            [self pushControllerWithName:@"candy" context:[(id)entry candy]];
        } else if ([entry isKindOfClass:[Candy class]]) {
            [self pushControllerWithName:@"candy" context:entry];
        }
    }
}

- (void)showError:(NSError*)error {
    [self.errorLabel setText:error.localizedDescription];
    self.state = WLWKContributionsStateError;
    [self.table setRowTypes:@[]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self updateContributions];
    [[WCSession defaultSession] dataSync:^(NSDictionary<NSString *,id> * reply) {
    } failure:^(NSError * error) {
    }];
}

- (void)updateContributions {
    if ([User currentUser]) {
        self.entries = [Contribution recentContributions:10];
    } else {
        [self showError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"No data for authorization. Please, check meWrap app on you iPhone."}]];
    }
}

@end



