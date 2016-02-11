//
//  FutureFuncTests.swift
//  Future
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class FutureFuncTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample1() {
        // This is an example of a functional test case.

        _ = future {
            Try("OK")
        }


        XCTAssert(true, "Pass")
    }


    func testFutureFuncCreatesFulfilledFuture() {
        let expect1 = self.expectationWithDescription("future should be fulfilled")

        let f = future { Try("OK") }
        XCTAssertNotNil(f)

        f.onComplete { _ in
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(f.isCompleted)
    }

    func testFutureFuncCreatesRejectedFuture() {
        let expect1 = self.expectationWithDescription("future should be rejected")
        let f = future { Try<Void>(error: TestError.Failed) }
        XCTAssertNotNil(f)

        f.onFailure { _ in
            expect1.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
        XCTAssertTrue(f.isCompleted)
    }

    func testPromiseVoidCtorWithErrorCreatesRejectedFuture() {
        let expect1 = self.expectationWithDescription("future should be rejected")
        let p = Promise<Void>(error: TestError.Failed)

        let future = p.future!
        XCTAssertNotNil(future)
        XCTAssertTrue(future.isCompleted)

        future.onFailure { _ in
            expect1.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: nil)
    }




}
