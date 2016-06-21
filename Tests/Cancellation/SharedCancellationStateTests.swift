//
//  SharedCancellationStateTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
@testable import FutureLib


class SharedCancellationStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitialSharedCancellationStateIsNotCancelled() {
        XCTAssertFalse(SharedCancellationState().isCancelled)
    }

    func testInitialSharedCancellationStateIsNotCompleted() {
        XCTAssertFalse(SharedCancellationState().isCompleted)
    }

    func testIsCancelledIsTrueWhenCancellingASharedCancellationState() {
        let cs = SharedCancellationState()
        cs.cancel()
        XCTAssertTrue(cs.isCompleted)
        XCTAssertTrue(cs.isCancelled)
    }

    func testIsCancelledIsFalseWhenCompletingASharedCancellationState() {
        let cs = SharedCancellationState()
        cs.complete()
        XCTAssertTrue(cs.isCompleted)
        XCTAssertFalse(cs.isCancelled)
    }



    func testOnCancelHandlerShouldExecuteWhenCancelled() {
        let cs = SharedCancellationState()
        let expect1 = self.expectation(withDescription: "cancellation handler should be called")
        _ = cs.onCancel(on: GCDAsyncExecutionContext()) {
            expect1.fulfill()
        }
        cs.cancel()
        waitForExpectations(withTimeout: 1, handler: nil)
        XCTAssertTrue(cs.isCompleted)
        XCTAssertTrue(cs.isCancelled)
    }

    func testOnCancelHandlerShouldExecuteIfCancelled() {
        let cs = SharedCancellationState()
        let expect1 = self.expectation(withDescription: "cancellation handler should be called")
        cs.cancel()
        _ = cs.onCancel(on: GCDAsyncExecutionContext()) {
            expect1.fulfill()
        }
        waitForExpectations(withTimeout: 1, handler: nil)
        XCTAssertTrue(cs.isCompleted)
        XCTAssertTrue(cs.isCancelled)
    }


}
