//
//  PromiseTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class PromiseTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }



    func testPromiseVoidDefaultCtorCreatesPendingFuture() {
        let expect1 = self.expectation(description: "future should be fulfilled")
        let p = Promise<Void>()

        let future = p.future!
        XCTAssertNotNil(future)
        XCTAssertFalse(future.isCompleted)

        future.onComplete { _ in
            expect1.fulfill()
        }

        p.fulfill()
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testPromiseVoidCtorWithValueCreatesFulfilledFuture() {
        let expect1 = self.expectation(description: "future should be fulfilled")
        let p = Promise<Void>(value: ())

        let future = p.future!
        XCTAssertNotNil(future)
        XCTAssertTrue(future.isCompleted)

        future.onComplete { _ in
            expect1.fulfill()
        }

        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testPromiseVoidCtorWithErrorCreatesRejectedFuture() {
        let expect1 = self.expectation(description: "future should be fulfilled")
        let p = Promise<Void>(error: TestError.failed)

        let future = p.future!
        XCTAssertNotNil(future)
        XCTAssertTrue(future.isCompleted)

        future.onFailure { _ in
            expect1.fulfill()
        }

        self.waitForExpectations(timeout: 1, handler: nil)
    }



}
