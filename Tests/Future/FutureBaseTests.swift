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
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<Int>()
        let sem = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            let future = promise.future!
            future.wait()
            sem.signal()
            expect.fulfill()
        }
        for _ in 0...3 {
            let timeout: DispatchTime = .now() + .milliseconds(100)
            XCTAssertTrue(sem.wait(timeout: timeout) == .timedOut)
        }
        promise.fulfill(1)
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }


    func testDataRace() {
        let expect = self.expectation(description: "future should be fulfilled")
        let promise = Promise<Int>()
        let sem = DispatchSemaphore(value: 0)

        func foo() {
            let future = promise.future!
            future.wait()
            sem.signal()
            expect.fulfill()
        }

        DispatchQueue.global().async(execute: foo)

        sleep(1)
        promise.fulfill(1) // a write op will be executed on the future's sync queue
        self.waitForExpectations(timeout: 0.1, handler: nil)
    }


    func testDataRace2() {
        let expect = self.expectation(description: "future should be fulfilled")
        let sem = DispatchSemaphore(value: 0)

        func task() -> Future<Int> {
            let promise = Promise<Int>()
            DispatchQueue.global().async {
                sleep(1)
                promise.fulfill(1)
            }
            return promise.future!
        }


        DispatchQueue.global().async {
            task().wait()
            sleep(1)
            expect.fulfill()
        }

        self.waitForExpectations(timeout: 12.1, handler: nil)
    }
    


    func testWaitBlocksTheCurrentThreadUntilAfterWaitGetsCancelled() {
        let expect = self.expectation(description: "future should be fulfilled")
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
            XCTAssertTrue(sem.wait(timeout: timeout) == .timedOut)
        }
        cr.cancel()
        self.waitForExpectations(timeout: 0.1, handler: nil)
        promise.fulfill(1)
    }




}
