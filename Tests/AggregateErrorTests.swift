//
//  AggregateErrorTests.swift
//  FutureLib
//
//  Created by Andreas Grosam on 05.01.16.
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


private enum TestErrorA: ErrorProtocol {
    case error
}

private enum TestErrorB: ErrorProtocol {
    case error
}

private enum TestErrorC: ErrorProtocol {
    case error
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
        
        var error = AggregateError(error: TestErrorA.error)
        error.add(TestErrorB.error)
        error.add(TestErrorC.error)
    
        XCTAssertTrue(error.description.contains("TestErrorA"))
        XCTAssertTrue(error.description.contains("Error"))
        XCTAssertTrue(error.description.contains("TestErrorB"))
        XCTAssertTrue(error.description.contains("TestErrorC"))
    }

}
