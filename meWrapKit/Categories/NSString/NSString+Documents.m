//
//  NSString+Documents.m
//  meWrap
//
//  Created by Ravenpod on 23.11.13.
//  Copyright (c) 2013 yo, gg. All rights reserved.
//

#import "NSString+Documents.h"

NSString *NSDocumentsDirectory(void) {
	static NSString *documentsPath = nil;
	if (documentsPath == nil) {
		documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	}
	return documentsPath;
}

NSString *NSDocumentsDirectoryPath(NSString *path) {
	return [NSDocumentsDirectory() stringByAppendingPathComponent:path];
}
