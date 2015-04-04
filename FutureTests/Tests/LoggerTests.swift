//
//  LoggerTests.swift
//  Future
//
//  Created by Andreas Grosam on 27/01/15.
//  Copyright (c) 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import Future

class LoggerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        var s = "Happy logging"
        let log = Logger(category: "Test", verbosity: Logger.Severity.Message);
        log.Message("\(s)!")
        XCTAssert(true, "Pass")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
