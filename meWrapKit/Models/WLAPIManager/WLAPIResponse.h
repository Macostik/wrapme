//
//  WLAPIResponse.h
//  meWrap
//
//  Created by Ravenpod on 25.03.14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, WLAPIResponseCode) {
	WLAPIResponseCodeSuccess = 0,
	WLAPIResponseCodeFailure = -1
};

/*!
 *  Class, that contains response from the WrapLive API including data, code and message
 */
@interface WLAPIResponse : NSObject

+ (instancetype)response:(NSDictionary*)dictionary;

/*!
 *  Dictionary representing the data from the returned response
 */
@property (strong, nonatomic) NSDictionary* data;

/*!
 *  Defines status of the response
 */
@property (nonatomic) NSInteger code;

/*!
 *  Contains description of the response
 */
@property (strong, nonatomic) NSString* message;

@end
