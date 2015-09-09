//
//  NSDictionary+Extended.h
//  Riot
//
//  Created by Ravenpod on 21.08.12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSDictionary (Extended)

- (id)tryObjectForKey:(id)key;

- (id)objectForPossibleKeys:(id)key, ... NS_REQUIRES_NIL_TERMINATION;

- (id)objectOfClass:(Class)class forKey:(id)key;
- (NSString*)stringForKey:(id)key;
- (NSURL*)urlForKey:(id)key;
- (NSNumber*)numberForKey:(id)key;
- (NSDate*)timestampDateForKey:(id)key;
- (NSDate*)dateForKey:(id)key;
- (NSDate*)dateForKey:(id)key withFormat:(NSString*)dateFormat;
- (NSArray*)arrayForKey:(id)key;
- (NSDictionary*)dictionaryForKey:(id)key;
- (CGFloat)floatForKey:(id)key;
- (BOOL)boolForKey:(id)key;
- (NSInteger)integerForKey:(id)key;
- (double)doubleForKey:(id)key;
- (NSString*)queryString;

- (NSDictionary *)unnulable;

- (id)merge:(NSDictionary*)dictionary;

- (instancetype)dictionaryBySwappingObjectsAndKeys;

@end

@interface NSMutableDictionary (Extended)

- (BOOL)trySetObject:(id)object forKey:(id)key;

@end