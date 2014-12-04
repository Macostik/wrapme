//
//  PGPhotoLibrary.m
//  PressGram-iOS
//
//  Created by Nikolay Rybalko on 4/17/13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "ALAssetsLibrary+Additions.h"
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>
#import "NSArray+Additions.h"
#import "NSString+Additions.h"

@implementation ALAssetsLibrary (PGTools)

+ (instancetype)library {
	static ALAssetsLibrary *_library = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    _library = [ALAssetsLibrary new];
	});
	return _library;
}

static NSDate *lastAssetCreationDate = nil;

- (void)hasChanges:(void (^)(BOOL))completion {
    [self enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            if (alAsset) {
                NSDate *date = [alAsset valueForProperty:ALAssetPropertyDate];
                if (lastAssetCreationDate) {
                    if ([lastAssetCreationDate compare:date] == NSOrderedAscending) {
                        if (completion) completion(YES);
                    } else {
                        if (completion) completion(NO);
                    }
                } else if (date) {
                    if (completion) completion(YES);
                }
                lastAssetCreationDate = date;
                *stop = YES; *innerStop = YES;
            }
        }];
    } failureBlock: ^(NSError *error) {
        if (completion) completion(NO);
    }];
}

- (void)enumerateGroups:(void (^)(ALAssetsGroup *))finish failure:(ALAssetsLibraryAccessFailureBlock)failure {
    [self enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock: ^(ALAssetsGroup *group, BOOL *stop) {
	    if (group) {
	        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
	        if ([group numberOfAssets] > 0) {
                finish(group);
            }
		} else {
	        finish(nil);
		}
	} failureBlock:failure];
}

- (void)groups:(void (^)(NSArray *groups))finish failure:(ALAssetsLibraryAccessFailureBlock)failure {
	NSMutableArray *groups = [NSMutableArray array];
    [self enumerateGroups:^(ALAssetsGroup *group) {
        if (group) {
            [groups addObject:group];
		} else {
            [groups sortUsingComparator:^NSComparisonResult(ALAssetsGroup *obj1, ALAssetsGroup *obj2) {
                if (obj1.isSavedPhotos) {
                    return NSOrderedAscending;
                } else if (obj2.isSavedPhotos) {
                    return NSOrderedDescending;
                } else {
                    return [@(obj2.numberOfAssets) compare:@(obj1.numberOfAssets)];
                }
            }];
	        dispatch_async(dispatch_get_main_queue(), ^{
	            finish([groups copy]);
			});
		}
    } failure:failure];
}

- (void)assets:(void (^)(NSArray *))finish failure:(ALAssetsLibraryAccessFailureBlock)failure {
	NSMutableArray *assets = [NSMutableArray array];
	
	ALAssetsLibraryGroupsEnumerationResultsBlock resultBlock = ^(ALAssetsGroup *group, BOOL *stop) {
		[group setAssetsFilter:[ALAssetsFilter allPhotos]];
		[group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock: ^(ALAsset *result, NSUInteger index, BOOL *stop) {
		    if (result)
				[assets addObject:result];
		}];
		
		if (group == nil) {
			dispatch_async(dispatch_get_main_queue(), ^{
			    finish(assets);
			});
		}
	};
	
	[[ALAssetsLibrary library] enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
	                                         usingBlock:resultBlock failureBlock:failure];
}

- (void)groups:(void (^)(NSArray *))groupsBlock assets:(void (^)(NSArray *))assetsBlock failure:(ALAssetsLibraryAccessFailureBlock)failure {
	NSMutableArray *groups = [NSMutableArray array];
	NSMutableArray *assets = [NSMutableArray array];
	
	[self enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock: ^(ALAssetsGroup *group, BOOL *stop) {
	    if (group) {
	        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
			
	        if (group.numberOfAssets > 0) {
	            [groups addObject:group];
				
	            if ([[group valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos) {
	                [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock: ^(ALAsset *result, NSUInteger index, BOOL *stop) {
	                    if (result) {
	                        [assets addObject:result];
						} else {
	                        dispatch_async(dispatch_get_main_queue(), ^{
	                            assetsBlock([NSArray arrayWithArray:assets]);
							});
						}
					}];
				}
			}
		}
	    else {
	        dispatch_async(dispatch_get_main_queue(), ^{
	            groupsBlock([NSArray arrayWithArray:groups]);
			});
		}
	} failureBlock: ^(NSError *error) {
	    dispatch_async(dispatch_get_main_queue(), ^{
	        failure(error);
		});
	}];
}

- (void)group:(void (^)(ALAssetsGroup *))groupBlock asset:(void (^)(ALAsset *))assetBlock finish:(void (^)(void))finish failure:(ALAssetsLibraryAccessFailureBlock)failure {
	ALAssetsLibraryGroupsEnumerationResultsBlock resultBlock = ^(ALAssetsGroup *group, BOOL *stop) {
		[group setAssetsFilter:[ALAssetsFilter allPhotos]];
		
		if (group && [group numberOfAssets] > 0) {
			groupBlock(group);
			[group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock: ^(ALAsset *result, NSUInteger index, BOOL *stop) {
			    if (result)
					assetBlock(result);
			}];
		}
	};
	
	[[ALAssetsLibrary library] enumerateGroupsWithTypes:ALAssetsGroupAll
	                                         usingBlock:resultBlock failureBlock:failure];
}

- (void)groupWithUrl:(NSURL *)url finish:(void (^)(ALAssetsGroup *))finish failure:(ALAssetsLibraryAccessFailureBlock)failure {
	[self groups: ^(NSArray *groups) {
	    ALAssetsGroup *result = nil;
		
	    for (ALAssetsGroup * group in groups) {
	        if ([url isEqual:group.url]) {
	            result = group;
	            break;
			}
		}
		
	    dispatch_async(dispatch_get_main_queue(), ^{
	        finish(result);
		});
	} failure:failure];
}

@end

@implementation ALAssetsGroup (PGTools)

- (NSNumber *)ID {
	return [self valueForProperty:ALAssetsGroupPropertyPersistentID];
}

- (NSString *)name {
	return [self valueForProperty:ALAssetsGroupPropertyName];
}

- (NSURL *)url {
	return [self valueForProperty:ALAssetsGroupPropertyURL];
}

- (ALAssetsGroupType)type {
    return [[self valueForProperty:ALAssetsGroupPropertyType] integerValue];
}

- (BOOL)isSavedPhotos {
    return self.type == ALAssetsGroupSavedPhotos;
}

- (void)assets:(void (^)(NSArray *assets))finish {
	NSMutableArray *assets = [NSMutableArray arrayWithCapacity:self.numberOfAssets];
	[self setAssetsFilter:[ALAssetsFilter allPhotos]];
	[self enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:
	 ^(ALAsset *result, NSUInteger index, BOOL *stop) {
		 if (result) {
			 [assets addObject:result];
		 }
		 else {
			 dispatch_async(dispatch_get_main_queue(), ^{
				 finish(assets);
			 });
		 }
	 }];
}

- (BOOL)isEqualToGroup:(ALAssetsGroup *)group {
	id id1 = self.ID;
	id id2 = group.ID;
	
	if ([id1 isKindOfClass:[NSNumber class]] && [id2 isKindOfClass:[NSNumber class]])
		return [id1 isEqualToNumber:id2];
	
	if ([id1 isKindOfClass:[NSString class]] && [id2 isKindOfClass:[NSString class]])
		return [id1 isEqualToString:id2];
	
	return NO;
}

@end

@implementation ALAsset (PGTools)

- (NSString *)ID {
	NSString *ID = objc_getAssociatedObject(self, "assetID");
	
	if (!ID) {
		NSArray *parameters = [[self.url query] componentsSeparatedByString:@"&"];
		
		for (NSString *parameter in parameters) {
			NSArray *items = [parameter componentsSeparatedByString:@"="];
			
			if ([items count] == 2) {
				if ([[[items objectAtIndex:0] lowercaseString] isEqualToString:@"id"]) {
					ID = [items objectAtIndex:1];
				}
			}
		}
		if (ID) {
			objc_setAssociatedObject(self, "assetID", ID, OBJC_ASSOCIATION_RETAIN);
		}
	}
	
	return ID;
}

- (NSURL *)url {
	return [self valueForProperty:ALAssetPropertyAssetURL];
}

- (NSDate *)date {
	NSDate *date = objc_getAssociatedObject(self, "date");
	
	if (!date) {
		date = [self valueForProperty:ALAssetPropertyDate];
		NSDateComponents *components = [[NSCalendar currentCalendar]
		                                components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit
										fromDate:date];
		date = [[NSCalendar currentCalendar]
		        dateFromComponents:components];
		objc_setAssociatedObject(self, "date", date, OBJC_ASSOCIATION_RETAIN);
	}
	
	return date;
}

- (CLLocation *)location {
	CLLocation *location = objc_getAssociatedObject(self, "location");
	
	if (!location) {
		location = [self valueForProperty:ALAssetPropertyLocation];
		objc_setAssociatedObject(self, "location", location, OBJC_ASSOCIATION_RETAIN);
	}
	
	return location;
}

- (BOOL)isEqualToAsset:(ALAsset *)asset {
	return [[self.url absoluteString] isEqualToString:[asset.url absoluteString]];
}

static size_t getAssetBytesCallback(void *info, void *buffer, off_t position, size_t count) {
	ALAssetRepresentation *rep = (__bridge id)info;
	size_t countRead = [rep getBytes:(uint8_t *)buffer fromOffset:position length:count error:NULL];
	return countRead;
}

static void releaseAssetCallback(void *info) {
	CFRelease(info);
}

- (UIImage *)image {
    ALAssetRepresentation* r = self.defaultRepresentation;
    return [UIImage imageWithCGImage:r.fullResolutionImage scale:r.scale orientation:(UIImageOrientation)r.orientation];
}

- (UIImage *)image:(CGFloat)maxSize {
	NSParameterAssert(maxSize > 0);
	
	ALAssetRepresentation *rep = [self defaultRepresentation];
	
	CGDataProviderDirectCallbacks callbacks = {
		.version = 0,
		.getBytePointer = NULL,
		.releaseBytePointer = NULL,
		.getBytesAtPosition = getAssetBytesCallback,
		.releaseInfo = releaseAssetCallback,
	};
	
	CGDataProviderRef provider = CGDataProviderCreateDirect((void *)CFBridgingRetain(rep), [rep size], &callbacks);
	CGImageSourceRef source = CGImageSourceCreateWithDataProvider(provider, NULL);
	
	NSDictionary *options = @{ (NSString *)kCGImageSourceCreateThumbnailFromImageAlways : @YES,
		                       (NSString *)kCGImageSourceThumbnailMaxPixelSize : @(maxSize),
		                       (NSString *)kCGImageSourceCreateThumbnailWithTransform : @YES };
	
	CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
	CFRelease(source);
	CFRelease(provider);
	
	if (!imageRef) {
		return nil;
	}
	
	NSString *adjustment = [[rep metadata] objectForKey:@"AdjustmentXMP"];
	if (adjustment) {
		CIImage *image = [CIImage imageWithCGImage:imageRef];
		NSData *xmpData = [adjustment dataUsingEncoding:NSUTF8StringEncoding];
		NSArray *filters = [CIFilter filterArrayFromSerializedXMP:xmpData inputImageExtent:image.extent error:NULL];
		if ([filters count] > 0) {
			CIContext *context = [CIContext contextWithOptions:nil];
			for (CIFilter *filter in filters) {
				[filter setValue:image forKey:kCIInputImageKey];
				image = [filter outputImage];
			}
			CGImageRelease(imageRef);
			imageRef = [context createCGImage:image fromRect:[image extent]];
		}
	}
	
	UIImage *toReturn = [UIImage imageWithCGImage:imageRef];
	
	CFRelease(imageRef);
	
	return toReturn;
}

@end
