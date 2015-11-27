//
//  WKInterfaceImage+WLImageFetcher.h
//  meWrap
//
//  Created by Ravenpod on 4/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface WKInterfaceImage (WLImageFetcher) <ImageFetching>

@property (strong, nonatomic) NSString* url;

@end

@interface WKInterfaceGroup (WLImageFetcher) <ImageFetching>

@property (strong, nonatomic) NSString* url;

@end
