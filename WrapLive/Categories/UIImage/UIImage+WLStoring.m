//
//  UIImage+WLStoring.m
//  WrapLive
//
//  Created by Sergey Maximenko on 31.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIImage+WLStoring.h"

@implementation UIImage (WLStoring)

- (void)storeWithName:(NSString*)name completion:(void (^)(NSString* path))completion {
	[self storeAtPath:[NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.jpg", name]] completion:completion];
}

- (void)storeAtPath:(NSString*)path completion:(void (^)(NSString* path))completion {
	__weak typeof(self)weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[UIImageJPEGRepresentation(weakSelf,1.0) writeToFile:path atomically:YES];
		dispatch_async(dispatch_get_main_queue(), ^{
			completion(path);
		});
    });
}

- (void)storeAsAvatar:(void (^)(NSString* path))completion {
	[self storeWithName:@"avatar" completion:completion];
}

- (void)storeAsCover:(void (^)(NSString* path))completion {
	[self storeWithName:@"cover" completion:completion];
}

- (void)storeAsImage:(void (^)(NSString *))completion {
	[self storeAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", [[NSProcessInfo processInfo] globallyUniqueString]]] completion:completion];
}

+ (void)removeImageAtPath:(NSString *)path {
	[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

+ (void)removeAllTemporaryImages {
	NSString* directoryPath = NSTemporaryDirectory();
	NSDirectoryEnumerator* enumerator = [[NSFileManager defaultManager] enumeratorAtPath:directoryPath];
	for (NSString* file in enumerator) {
		[UIImage removeImageAtPath:[directoryPath stringByAppendingPathComponent:file]];
	}
}

@end
