//
//  FutureRecoverTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class FutureRecoverTests: XCTestCase {

    private let timeout: NSTimeInterval = 1000

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: recover(_:)

    func testRecoverReturnsSuccesFutureWithPendingFuturePropagatesSuccessValueWhenCompletedWithSuccessValue() {
        let expect = self.expectationWithDescription("future should be completed")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        asyncTask().recover { error in
            XCTFail("unexpected reecover")
            return "Failed"
        }
        .onSuccess { value in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }


    func testRecoverReturnsSucceededFutureWithPendingFutureInvokesRecoverHandlerWhenCompletedWithError() {
        let expect1 = self.expectationWithDescription("future1 should be completed")
        let expect2 = self.expectationWithDescription("future2 should be completed")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        asyncTask().recover { error in
            XCTAssertTrue(TestError.Failed == error)
            expect1.fulfill()
            return "Failed"
        }
        .onSuccess { value in
            XCTAssertEqual("Failed", value)
            expect2.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }


    func testRecoverReturnsFailedFutureWithPendingFutureInvokesRecoverHandlerWhichThrowsErrorWhenCompletedWithError() {
        let expect1 = self.expectationWithDescription("future1 should be completed")
        let expect2 = self.expectationWithDescription("future2 should be completed")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        asyncTask().recover { error in
            XCTAssertTrue(TestError.Failed == error)
            expect1.fulfill()
            throw TestError.Failed
        }
        .onFailure { error in
            XCTAssertTrue(TestError.Failed == error)
            expect2.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }



    // MARK: recoeverWith(_:)

    func testRecoverWithReturnsSuccesFutureWithPendingFuturePropagatesSuccessValueWhenCompletedWithSuccessValue() {
        let expect = self.expectationWithDescription("future should be completed")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        asyncTask().recoverWith { error in
            XCTFail("unexpected reecover")
            return Future<String>.succeededAfter(0.01, value: "Deferred Failed")
        }
        .onSuccess { value in
            XCTAssertEqual("OK", value)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }


    func testRecoverWithReturnsSucceededFutureWithPendingFutureInvokesRecoverHandlerWhenCompletedWithDeferredError() {
        let expect1 = self.expectationWithDescription("future1 should be completed")
        let expect2 = self.expectationWithDescription("future2 should be completed")
        let asyncTask: ()-> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.001) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        asyncTask().recoverWith { error in
            XCTAssertTrue(TestError.Failed == error)
            expect1.fulfill()
            return Future<String>.succeededAfter(0.01, value: "Deferred Failed")
        }
        .onSuccess { value in
            XCTAssertEqual("Deferred Failed", value)
            expect2.fulfill()
        }
        self.waitForExpectationsWithTimeout(timeout, handler: nil)
    }





}
