//
//  FutureLibImportTests.m
//  FutureLib
//
//  Created by Andreas Grosam on 05/07/15.
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <FutureLib/FutureLib-Swift.h>

@interface FutureLibImportTests : XCTestCase

@end

@implementation FutureLibImportTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    Promise<NSObject*>* promise = [[Promise alloc] init];
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
