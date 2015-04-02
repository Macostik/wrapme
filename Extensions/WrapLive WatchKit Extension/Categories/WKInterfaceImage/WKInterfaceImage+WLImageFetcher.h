//
//  WKInterfaceImage+WLImageFetcher.h
//  WrapLive
//
//  Created by Sergey Maximenko on 4/2/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface WKInterfaceImage (WLImageFetcher) <WLImageFetching>

@property (strong, nonatomic) NSString* url;

@end

@interface WKInterfaceGroup (WLImageFetcher) <WLImageFetching>

@property (strong, nonatomic) NSString* url;

@end
