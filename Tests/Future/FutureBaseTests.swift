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
        promise.reject(TestError.failed)
        XCTAssertTrue(future.isCompleted)
        XCTAssertFalse(future.isSuccess)
        XCTAssertTrue(future.isFailure)
    }

    
    
    
    // MARK: wait()
    

    func testWaitBlocksTheCurrentThreadUntilAfterTheFutureIsCompleted() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<Int>()
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let future = promise.future!
            future.wait()
            sem.signal()
            expect.fulfill()
        }
        let timeout: DispatchTime = .now() + .milliseconds(100) 
            //DispatchTime(0.1 * Double(NSEC_PER_SEC))
        for _ in 0...3 {
            XCTAssertTrue(sem.wait(timeout: timeout) == .TimedOut)
        }
        promise.fulfill(1)
        self.waitForExpectations(withTimeout: 0.1, handler: nil)
    }


    func testWaitBlocksTheCurrentThreadUntilAfterWaitGetsCancelled() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<Int>()
        let cr = CancellationRequest()
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let future = promise.future!
            future.wait(cr.token)
            sem.signal()
            expect.fulfill()
        }
        let timeout: DispatchTime = .now() + .milliseconds(100) 
        for _ in 0...3 {
            XCTAssertTrue(sem.wait(timeout: timeout) == .TimedOut)
        }
        cr.cancel()
        self.waitForExpectations(withTimeout: 0.1, handler: nil)
        promise.fulfill(1)
    }




}
