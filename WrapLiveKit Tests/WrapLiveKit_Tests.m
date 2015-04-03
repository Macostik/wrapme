//
//  WrapLiveKit_Tests.m
//  WrapLiveKit Tests
//
//  Created by Sergey Maximenko on 4/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <WrapLiveKit/WrapLiveKit.h>

@interface WrapLiveKit_Tests : XCTestCase

@end

@implementation WrapLiveKit_Tests

- (void)testInitMethod {
    // This is an example of a functional test case.
    
    NSString *string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat width = 320;
    [self measureBlock:^{
        CGFloat height = WLCalculateHeightString_Init(string, font, width);
    }];
}

- (void)testNewMethod {
    // This is an example of a functional test case.
    
    NSString *string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat width = 320;
    [self measureBlock:^{
        CGFloat height = WLCalculateHeightString(string, font, width);
    }];
}

- (void)testOldMethod {
    // This is an example of a functional test case.
    
    NSString *string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat width = 320;
    
    [self measureBlock:^{
        CGFloat height = [string heightWithFont:font width:width];
    }];
}

- (void)testResults {
    NSString *string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat width = 320;
    XCTAssertEqualWithAccuracy([string heightWithFont:font width:width], WLCalculateHeightString(string, font, width), 2);
    
    string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    
    XCTAssertEqualWithAccuracy([string heightWithFont:font width:width], WLCalculateHeightString(string, font, width), 2);
    
    string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    
    XCTAssertEqualWithAccuracy([string heightWithFont:font width:width], WLCalculateHeightString(string, font, width), 2);
    
    string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class. This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    
    XCTAssertEqualWithAccuracy([string heightWithFont:font width:width], WLCalculateHeightString(string, font, width), 2);
}

@end
