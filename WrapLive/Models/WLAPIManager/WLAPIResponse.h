//
//  WLAPIResponse.h
//  WrapLive
//
//  Created by Sergey Maximenko on 25.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "JSONModel.h"

typedef NS_ENUM(NSInteger, WLAPIResponseCode) {
	WLAPIResponseCodeSuccess,
	WLAPIResponseCodeFailure
};

/**
 *  Class, that contains response from the WrapLive API including data, code and message
 */
@interface WLAPIResponse : JSONModel

/**
 *  Dictionary representing the data from the returned response
 */
@property (strong, nonatomic) NSDictionary* data;

/**
 *  Defines status of the response
 */
@property (nonatomic) NSInteger code;

/**
 *  Contains description of the response
 */
@property (strong, nonatomic) NSString* message;

@end
