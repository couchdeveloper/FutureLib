//
//  AggregateErrorTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 05.01.16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


private enum TestErrorA: ErrorType {
    case Error
}

private enum TestErrorB: ErrorType {
    case Error
}

private enum TestErrorC: ErrorType {
    case Error
}


class AggregateErrorTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        
        let error = AggregateError(TestErrorA.Error)
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
