//
//  FutureBaseMapToTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class FutureBaseMapToTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testMapTo() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        
        let task: () -> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        
        
        let future: Future<String> = task().mapTo()
        
        future.onComplete { result in
            switch result {
            case .Success(let value):
                XCTAssertEqual("OK", value)
            case .Failure:
                XCTFail("unexpected failure")
            }
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    


}
