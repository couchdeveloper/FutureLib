//
//  FutureBaseContinueWithTests.swift
//  FutureLib
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib

class FutureBaseContinueWithTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test1() {

        let future = Future<Int>.succeeded(0)
        let ec = ConcurrentAsync()
        let ct = CancellationRequest().token

        let _ = future.continueWith { f in
        }
        let _ = future.continueWith() { f in
        }
        let _ = future.continueWith(ec: ec, ct: ct) { f in
        }
        let _ = future.continueWith(ct: ct) { f in
        }
        let _ = future.continueWith(ec: ec) { f in
        }


        let futureBase: FutureBaseType = Future<Int>.succeeded(0)
        _ = futureBase.continueWith { f  in
        }
        _ = futureBase.continueWith() { f in
        }
        _ = futureBase.continueWith(ec: ec, ct: ct) { f in
        }
        _ = futureBase.continueWith(ct: ct) { f in
        }
        _ = futureBase.continueWith(ec: ec) { f in
        }
    }

    func testPendingFutureShouldExecuteContinuationWhenFulfilled() {
        let expect = self.expectation(withDescription: "future should be fulfilled")

        let task: () -> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.fulfill("OK")
            }
            return promise.future!
        }

        let future = task()

        let _ = future.continueWith { futureBase in
            XCTAssertTrue(futureBase.isCompleted)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testPendingFutureShouldExecuteContinuationWhenRejected() {
        let expect = self.expectation(withDescription: "future should be fulfilled")

        let task: () -> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.01) {
                promise.reject(TestError.failed)
            }
            return promise.future!
        }

        let future = task()

        let _ = future.continueWith { futureBase in
            XCTAssertTrue(futureBase.isFailure)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testPendingFutureShouldExecuteContinuationWhenCancelled() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        Log.Info("1")
        let task: () -> Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.5) {
                Log.Info("2")
                promise.fulfill("OK")
            }
            return promise.future!
        }

        let future = task()
        let _ = future.continueWith(ct: cr.token) { (futureBase) -> () in
            Log.Info("3")
            XCTAssertTrue(cr.token.isCancellationRequested)
            XCTAssertFalse(futureBase.isCompleted)
            expect.fulfill()
        }

        schedule_after(0.01) {
            cr.cancel()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testFulfilledFutureShouldExecuteContinuation() {
        let expect = self.expectation(withDescription: "future should be fulfilled")

        let task: () -> Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }

        let future = task()

        let _ = future.continueWith { futureBase in
            XCTAssertTrue(futureBase.isCompleted)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testRejectedFuturewShouldExecuteContinuation() {
        let expect = self.expectation(withDescription: "future should be fulfilled")

        let task: () -> Future<String> = {
            let promise = Promise<String>(error: TestError.failed)
            return promise.future!
        }

        let future = task()

        let _ = future.continueWith { futureBase in
            XCTAssertTrue(futureBase.isFailure)
            expect.fulfill()
        }
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testFulfilledFutureWithCancelledTokenShouldExecuteContinuation() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let cr = CancellationRequest()
        cr.cancel()
        let task: () -> Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }

        let future = task()
        let _ = future.continueWith(ct: cr.token) { (futureBase) -> () in
            XCTAssertTrue(cr.token.isCancellationRequested)
            XCTAssertTrue(futureBase.isCompleted)
            expect.fulfill()
        }

        self.waitForExpectations(withTimeout: 1, handler: nil)
    }




    func testGivenAFulfilledFutureTheContinuationShouldExecute1() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            promise.fulfill("OK")
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec) { f in
                XCTAssertTrue(f.isSuccess)
                XCTAssertNotNil((f as? Future<String>)?.result)
                let result = (f as! Future<String>).result!
                let value = try! result.get()
                XCTAssertEqual("OK", value)
                expect.fulfill()
            }

        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testGivenAFulfilledFutureTheContinuationShouldExecute2() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            promise.fulfill("OK")
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec, ct: CancellationTokenNone()) { (futureBase) in
                XCTAssertTrue(futureBase.isSuccess)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testGivenARejectedFutureTheContinuationShouldExecute1() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            promise.reject(TestError.failed)
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec, ct: CancellationTokenNone()) { f -> Void in
                XCTAssertTrue(f.isCompleted)
                XCTAssertTrue(f.isFailure)
                expect.fulfill()
            }

        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testGivenARejectedFutureTheContinuationShouldExecute2() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            promise.reject(TestError.failed)
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec, ct: CancellationTokenNone()) { (futureBase) in
                XCTAssertTrue(futureBase.isCompleted)
                XCTAssertTrue(futureBase.isFailure)
                expect.fulfill()
            }

        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testGivenAPendingFutureTheContinuationShouldExecuteAfterCompleteWithSuccess1() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec) { f in
                XCTAssertTrue(f.isCompleted)
                XCTAssertTrue(f.isSuccess)
                expect.fulfill()
            }
            promise.fulfill("OK")
        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testGivenAPendingFutureTheContinuationShouldExecuteAfterCompleteWithSuccess2() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec, ct: CancellationTokenNone()) { (futureBase) in
                XCTAssertTrue(futureBase.isCompleted)
                XCTAssertTrue(futureBase.isSuccess)
                expect.fulfill()
            }
            promise.fulfill("OK")
        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testGivenAPendingFutureTheContinuationShouldExecuteAfterCompleteWithFailure1() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec) { f in
                XCTAssertTrue(f.isCompleted)
                XCTAssertTrue(f.isFailure)
                expect.fulfill()
            }
            promise.reject(TestError.failed)
        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

    func testGivenAPendingFutureTheContinuationShouldExecuteAfterCompleteWithFailure2() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future: FutureBaseType = promise.future!
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec, ct: CancellationTokenNone()) { (futureBase) in
                XCTAssertTrue(futureBase.isCompleted)
                XCTAssertTrue(futureBase.isFailure)
                expect.fulfill()
            }
            promise.reject(TestError.failed)
        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testGivenAPendingFutureTheContinuationShouldExecuteAfterCancellation() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let cr = CancellationRequest()
            let future: FutureBaseType = promise.future!
            let ec = GCDAsyncExecutionContext()
            XCTAssertFalse(future.isCompleted)
            XCTAssertFalse(future.isSuccess)
            XCTAssertFalse(future.isFailure)
            _ = future.continueWith(ec: ec, ct: cr.token) { (futureBase) in
                XCTAssertFalse(futureBase.isCompleted)
                XCTAssertFalse(futureBase.isSuccess)
                XCTAssertFalse(futureBase.isFailure)
                expect.fulfill()
            }
            cr.cancel()
        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testGivenAPendingFutureAndACancellationRequestTheContinuationShouldExecute() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let cr = CancellationRequest()
            cr.cancel()
            let future: FutureBaseType = promise.future!
            let ec = GCDAsyncExecutionContext()
            _ = future.continueWith(ec: ec, ct: cr.token) { (futureBase) in
                XCTAssertFalse(futureBase.isCompleted)
                XCTAssertFalse(futureBase.isSuccess)
                XCTAssertFalse(futureBase.isFailure)
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }


    func testExample1b() {
        let expect = self.expectation(withDescription: "future should be fulfilled")
        let promise = Promise<String>()
        let test:()->() = {
            let future = promise.future!
            promise.fulfill("OK")
            let ec = GCDAsyncExecutionContext()
            let _ = future.continueWith(ec: ec) { f in
                expect.fulfill()
            }

        }
        test()
        self.waitForExpectations(withTimeout: 1, handler: nil)
    }

}
