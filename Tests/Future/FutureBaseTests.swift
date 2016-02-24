//
//  FutureBaseTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib


class FutureBaseTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    // MARK: Invariants

    func testPendingFutureInvariants() {
        let promise = Promise<String>()
        let future: FutureBaseType = promise.future!
        XCTAssertFalse(future.isCompleted)
        XCTAssertFalse(future.isSuccess)
        XCTAssertFalse(future.isFailure)
    }

    func testFulfilledFutureInvariants() {
        let promise = Promise<String>()
        let future: FutureBaseType = promise.future!
        promise.fulfill("OK")
        XCTAssertTrue(future.isCompleted)
        XCTAssertTrue(future.isSuccess)
        XCTAssertFalse(future.isFailure)
    }

    func testFailedFutureInvariants() {
        let promise = Promise<String>()
        let future: FutureBaseType = promise.future!
        promise.reject(TestError.Failed)
        XCTAssertTrue(future.isCompleted)
        XCTAssertFalse(future.isSuccess)
        XCTAssertTrue(future.isFailure)
    }

    
    
    
    // MARK: wait()
    

    func testWaitBlocksTheCurrentThreadUntilAfterTheFutureIsCompleted() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<Int>()
        let sem = dispatch_semaphore_create(0)
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let future = promise.future!
            future.wait()
            dispatch_semaphore_signal(sem)
            expect.fulfill()
        }
        let timeout: dispatch_time_t = dispatch_time_t(0.1 * Double(NSEC_PER_SEC))
        for _ in 0...3 {
            XCTAssertTrue(dispatch_semaphore_wait(sem, timeout) != 0)
        }
        promise.fulfill(1)
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }


    func testWaitBlocksTheCurrentThreadUntilAfterWaitGetsCancelled() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<Int>()
        let cr = CancellationRequest()
        let sem = dispatch_semaphore_create(0)
        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let future = promise.future!
            future.wait(cr.token)
            dispatch_semaphore_signal(sem)
            expect.fulfill()
        }
        let timeout: dispatch_time_t = dispatch_time_t(0.1 * Double(NSEC_PER_SEC))
        for _ in 0...3 {
            XCTAssertTrue(dispatch_semaphore_wait(sem, timeout) != 0)
        }
        cr.cancel()
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
        promise.fulfill(1)
    }




}
