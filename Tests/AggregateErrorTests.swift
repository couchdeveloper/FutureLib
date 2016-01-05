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

    func testAggregateErrorDescriptionShouldListErrors() {
        
        var error = AggregateError(error: TestErrorA.Error)
        error.add(TestErrorB.Error)
        error.add(TestErrorC.Error)
    
        XCTAssertTrue(error.description.contains("TestErrorA"))
        XCTAssertTrue(error.description.contains("Error"))
        XCTAssertTrue(error.description.contains("TestErrorB"))
        XCTAssertTrue(error.description.contains("TestErrorC"))
    }

}
