//
//  WLEntryFetching.m
//  WrapLive
//
//  Created by Sergey Maximenko on 8/28/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLEntryFetching.h"
#import "NSObject+Extension.h"

@interface WLEntryFetching () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController* results;

@property (weak, nonatomic) id target;

@property (nonatomic) SEL action;

@property (nonatomic) NSTimeInterval delay;

@end

@implementation WLEntryFetching

+ (instancetype)fetching:(NSString *)name configuration:(void (^)(NSFetchRequest *))configure {
    return [[self alloc] initWithName:name configuration:configure];
}

- (instancetype)initWithName:(NSString *)name configuration:(void (^)(NSFetchRequest *))configure {
    self = [super init];
    if (self) {
        [self setup:name configuration:configure];
    }
    return self;
}

- (void)setup:(NSString*)name configuration:(void (^)(NSFetchRequest *))configure {
    self.request = [[NSFetchRequest alloc] init];
    if (configure) configure(self.request);
    self.results = [[NSFetchedResultsController alloc] initWithFetchRequest:self.request managedObjectContext:[WLEntryManager manager].context sectionNameKeyPath:nil cacheName:name];
    self.results.delegate = self;
}

- (void)perform {
    [self.results performFetch:NULL];
}

- (NSMutableOrderedSet *)content {
    return [NSMutableOrderedSet orderedSetWithArray:self.results.fetchedObjects];
}

- (void)addTarget:(id)target action:(SEL)action delay:(NSTimeInterval)delay {
    self.target = target;
    self.action = action;
}

- (void)addTarget:(id)target action:(SEL)action {
    [self addTarget:target action:action delay:0.5f];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.delegate fetching:self didChangeContent:self.content];
    if (self.target) {
        [self.target enqueueSelectorPerforming:self.action afterDelay:self.delay];
    }
}

@end
