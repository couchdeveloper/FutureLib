//
//  CancellationStateTests.swift
//  FutureLib
//
//  Copyright © 2016 Andreas Grosam. All rights reserved.
//

import XCTest
import Dispatch
import Darwin.C
@testable import FutureLib


class CancellationStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testInitialSelfIsNotCancelled() {
        XCTAssertFalse(CancellationState().isCancelled)
    }

    func testInitialSelfCountEqualsZero() {
        XCTAssertEqual(0, CancellationState().count)
    }
    
    func testInitialSelfIsNotCompleted() {
        XCTAssertFalse(CancellationState().isCompleted)
    }

    func testIsCancelledIsTrueWhenSelfHasBeenCancelled() {
        let cs = CancellationState()
        cs.cancel()
        XCTAssertTrue(cs.isCompleted)
        XCTAssertTrue(cs.isCancelled)
    }

    func testIsCancelledIsFalseWhenSelfHasBeenCancelled() {
        let cs = CancellationState()
        cs.invalidate()
        XCTAssertTrue(cs.isCompleted)
        XCTAssertFalse(cs.isCancelled)
    }

    func testOnCancelHandlerShouldExecuteWheSelfHasBeenCancelled() {
        let cs = CancellationState()
        let expect1 = self.expectation(description: "cancellation handler should be called")
        _ = cs.onCancel {
            expect1.fulfill()
        }
        cs.cancel()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(cs.isCompleted)
        XCTAssertTrue(cs.isCancelled)
    }
    
    func testCountEqualsNumberOfRegisteredHandlers() {
        let cs = CancellationState()
        let expect1 = self.expectation(description: "cancellation handler should be called")
        _ = cs.onCancel {
            expect1.fulfill()
        }
        XCTAssertEqual(1, cs.count)
        cs.cancel()
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertEqual(0, cs.count)
    }
    
    func testOnCancelHandlerShouldExecuteWhenSelfHasBeenCancelled() {
        let cs = CancellationState()
        let expect1 = self.expectation(description: "cancellation handler should be called")
        cs.cancel()
        _ = cs.onCancel {
            expect1.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(cs.isCompleted)
        XCTAssertTrue(cs.isCancelled)
    }


}
