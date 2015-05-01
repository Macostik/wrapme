//
//  NSString+Documents.m
//  PressGram-iOS
//
//  Created by Sergey Maximenko on 23.11.13.
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
