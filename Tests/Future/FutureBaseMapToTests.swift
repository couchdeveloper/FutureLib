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
        let expect = self.expectation(description: "future should be fulfilled")

        func task() -> Future<String> {
            let promise = Promise<String>()
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                promise.fulfill("OK")
            }
            return promise.future!
        }


        let future: Future<String> = task().mapTo()

        future.onComplete { result in
            switch result {
            case .success(let value):
                XCTAssertEqual("OK", value)
            case .failure:
                XCTFail("unexpected failure")
            }
            expect.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }





}
