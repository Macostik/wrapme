//
//  NSArray+Additions.h
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 8/1/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef id(^MapBlock)(id item);
typedef BOOL(^SelectBlock)(id item);
typedef void(^EnumBlock)(id item);
typedef BOOL(^EqualityBlock)(id first, id second);

@interface NSArray (Additions)

- (NSArray*)arrayByRemovingObject:(id)object;

- (NSArray*)arrayByRemovingObjectsFromArray:(NSArray *)array;

- (NSArray*)arrayByReplacingObject:(id)object withObject:(id)replaceObject;

- (id)safeObjectAtIndex:(NSInteger)index;

+ (instancetype)arrayWithResourcePropertyListNamed:(NSString*)name;

- (NSArray*)arrayByAddingUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality;

- (NSArray*)arrayByAddingUniqueObject:(id)object equality:(EqualityBlock)equality;

- (NSArray*)arrayByRemovingUniqueObject:(id)object equality:(EqualityBlock)equality;

- (NSArray*)map:(MapBlock)block;

- (id)selectObject:(SelectBlock)block;

- (NSArray*)selectObjects:(SelectBlock)block;

- (void)all:(EnumBlock)block;

- (NSArray*)unique;

- (NSArray*)uniqueByBlock:(EqualityBlock)block;

- (BOOL)containsObject:(id)target byBlock:(EqualityBlock)block;

@end

@interface NSMutableArray (Additions)

- (BOOL)replaceObject:(id)object withObject:(id)replaceObject;

- (void)addUniqueObjects:(NSArray *)objects equality:(EqualityBlock)equality;

- (void)addUniqueObject:(id)object equality:(EqualityBlock)equality;

- (BOOL)removeUniqueObject:(id)object equality:(EqualityBlock)equality;

@end
