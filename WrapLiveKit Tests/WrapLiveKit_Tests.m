//
//  mojiKit_Tests.m
//  mojiKit Tests
//
//  Created by Sergey Maximenko on 4/3/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <mojiKit/mojiKit.h>

@interface mojiKit_Tests : XCTestCase

@end

@implementation mojiKit_Tests

- (void)testNewMethod {
    // This is an example of a functional test case.
    
    NSString *string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat width = 320;
    [self measureBlock:^{
        run_loop(1000, ^(NSUInteger i) {
            CGFloat height = WLCalculateHeightString(string, font, width);
        });
    }];
}

- (void)testOldMethod {
    // This is an example of a functional test case.
    
    NSString *string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    UIFont *font = [UIFont systemFontOfSize:15];
    CGFloat width = 320;
    
    [self measureBlock:^{
        run_loop(1000, ^(NSUInteger i) {
            CGFloat height = [string heightWithFont:font width:width];
        });
    }];
}

- (void)testResults {
    NSString *string = @"This is an example of a functional test case. Put teardown code here. This method is called after the invocation of each test method in the class. Put setup code here. This method is called before the invocation of each test method in the class.";
    UIFont *font = [UIFont systemFontOfSize:34];
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
