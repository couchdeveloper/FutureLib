//
//  FutureTests.swift
//  FutureTests
//
//  Copyright © 2015 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib



class Dummy {
    let _expect: XCTestExpectation
    init(_ expect: XCTestExpectation) {
        _expect = expect
    }
    deinit {
        _expect.fulfill()
    }
}




/// Initialize and configure the Logger
internal var Log: Logger  = {
    var target = ConsoleEventTarget()
    target.writeOptions = .Sync
    return Logger(category: "FutureLibTests", verbosity: Logger.Severity.Trace, targets: [target])
}()



class Foo<T> {
    typealias ArrayClosure = ([T])->()
}

class FutureTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }




    func testGivenAPendingFutureWithRegisteredSuccessHandlerWhenFulfilledItShouldRunItsSuccessHandler() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.1) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().then { str in
            XCTAssertEqual("OK", str)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testGivenAFulfilledFutureWithRegisteredSuccessHandlerItShouldExecuteItsSuccessHandler() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().then { str in
            XCTAssertEqual("OK", str)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testGivenAPendingFutureWithRegisteredFailureHandlerWhenRejectedItShouldRunItsFailureHandler() {
        let expect = self.expectationWithDescription("future should be rejected")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.1) {
                promise.reject(TestError.Failed)
            }
            return promise.future!
        }
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.Failed == error)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testGivenARejectedFutureWhenRegisteringFailureHandlerItShouldRunItsFailureHandler() {
        let expect = self.expectationWithDescription("future should be rejected")
        let test:()->Future<String> = {
            let promise = Promise<String>(error: TestError.Failed)
            return promise.future!
        }
        test().onFailure { error -> () in
            XCTAssertTrue(TestError.Failed == error)
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }


    func testGivenAPendingFutureWithRegisteredSuccessHandlerItShouldExecuteItsSuccessHandlerOnTheMainThread() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>()
            schedule_after(0.1) {
                promise.fulfill("OK")
            }
            return promise.future!
        }
        test().then(ec: GCDAsyncExecutionContext(dispatch_get_main_queue())) { str in
            XCTAssertTrue(NSThread.isMainThread())
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testGivenAFulfilledFutureWithRegisteredSuccessHandlerItShouldExecuteItsSuccessHandlerOnTheMainThread() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test: ()->Future<String> = {
            let promise = Promise<String>(value: "OK")
            return promise.future!
        }
        test().then(ec: GCDAsyncExecutionContext(dispatch_get_main_queue())) { str in
            XCTAssertTrue(NSThread.isMainThread())
            expect.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }



    func testExample3() {
        let expect1 = self.expectationWithDescription("future1 should be fulfilled")
        let expect2 = self.expectationWithDescription("future2 should be fulfilled")
        let expect3 = self.expectationWithDescription("future3 should be fulfilled")
        let expect4 = self.expectationWithDescription("future4 should be fulfilled")
        let expect5 = self.expectationWithDescription("future5 should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            expect1.fulfill()
            return 1
            }
        .then { x -> Int in
            XCTAssertEqual(1, x)
            expect2.fulfill()
            return 2
        }
        .then { x -> Int in
            XCTAssertEqual(2, x)
            expect3.fulfill()
            return 3
        }
        .then { x -> String in
            XCTAssertEqual(3, x)
            expect4.fulfill()
            return "done"
        }
        .then { _ in
            0
        }
        .then { x in
            XCTAssertEqual(0, x)
            expect5.fulfill()
        }

        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testExample5() {
        let expect = self.expectationWithDescription("future should be rejected")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            return 1
        }
        .then { x -> Int in
            XCTAssertEqual(1, x)
            if x != 0 {
                throw TestError.Failed
            }
            else {
                return x
            }
        }
        .recover { err -> Int in
            XCTAssertTrue(TestError.Failed == err)
            return -1
        }
        .then { x -> String in
            XCTAssertEqual(-1, x)
            return "unused"
        }
        .finally { _ -> () in
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testExample6() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            return 1
        }
        .then { x -> Int in
            XCTAssertEqual(1, x)
            return 2
        }
        .recover { err -> Int in
            XCTFail("unexpected")
            return -1
        }
        .then { x -> String in
            XCTAssertEqual(2, x)
            return "unused"
        }
        .finally { _ -> () in
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testExample7() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            XCTAssertEqual("OK", str)
            return 1
        }
        .then { x -> Future<Int> in
            XCTAssertEqual(1, x)
            let promise = Promise(value: 2)
            return promise.future!
        }
        .then { x -> String in
            XCTAssertEqual(2, x)
            return "unused"
        }
        .finally { _ -> () in
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }


    func testExample8() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            return 1
        }
        .then { x -> Future<Int> in
            XCTAssertEqual(1, x)
            let promise = Promise<Int>()
            dispatch_async(dispatch_get_main_queue()) {
                promise.fulfill(2)
            }
            return promise.future!
        }
        .then { x -> String in
            XCTAssertEqual(2, x)
            return "unused"
        }
        .finally { _ -> () in
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }

//    // Livetime

    func testFutureShouldDeallocateIfThereAreNoObservers() {
        let promise = Promise<Int>()
        weak var weakRef: Future<Int>?
        func t() {
            let future = promise.future
            weakRef = future
        }
        t()
        XCTAssertNil(weakRef)
    }

    func testFutureShouldDeallocateIfThereAreNoObservers2() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectationWithDescription("cancellation handler should be unregistered")

        dispatch_async(dispatch_get_global_queue(0, 0)) {
            let future = promise.future!
            let d1 = Dummy(expect1)
            future.then(cancellationToken: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
                return
            }
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
            cr.cancel()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testFutureShouldDeallocateIfThereAreNoObservers3() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectationWithDescription("cancellation handler should be unregistered")
        let expect2 = self.expectationWithDescription("cancellation handler should be unregistered")

        dispatch_async(dispatch_get_global_queue(0,0)) {
            let future = promise.future!
            let d1 = Dummy(expect1)
            let d2 = Dummy(expect2)

            future.then(cancellationToken: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
                return
            }
            future.then(cancellationToken: ct) { i -> () in
                XCTFail("unexpected")
                print(d2)
                return
            }
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
            cr.cancel()
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testFutureShouldDeallocateIfThereAreNoObservers4() {
        let cr = CancellationRequest()
        let ct = cr.token
        let promise = Promise<Int>()
        let expect1 = self.expectationWithDescription("cancellation handler should be unregistered")
        let expect2 = self.expectationWithDescription("cancellation handler should be unregistered")
        let expect3 = self.expectationWithDescription("cancellation handler should be unregistered")

        dispatch_async(dispatch_get_global_queue(0,0)) {
            let future = promise.future!
            let d1 = Dummy(expect1)
            let d2 = Dummy(expect2)

            future.then(cancellationToken: ct) { i -> () in
                XCTFail("unexpected")
                print(d1)
                return
            }
            future.then(cancellationToken: ct) { i -> () in
                XCTFail("unexpected")
                print(d2)
                return
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
                cr.cancel()
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(10 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
                    let d3 = Dummy(expect3)
                    future.then(cancellationToken: cr.token) { i -> () in
                        XCTFail("unexpected")
                        print(d3)
                        return
                    }
                }
            };
        }

        waitForExpectationsWithTimeout(1, handler: nil)
    }



    func testFutureShouldNotDeallocateIfThereIsOneObserver() {
        weak var weakRef: Future<Int>?
        let promise = Promise<Int>()
        let sem = dispatch_semaphore_create(0)
        func t() {
            let future = promise.future!
            future.then { result -> () in
                dispatch_semaphore_signal(sem)
                return
            }
            weakRef = future
        }
        t()
        XCTAssertNotNil(weakRef)
        promise.fulfill(0)
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
        let future = weakRef
        XCTAssertNil(future)
    }

    func testFutureShouldCompleteWithBrokenPromiseIfPromiseDeallocatesPrematurely() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let promise = Promise<String>()
            promise.future!.onFailure { error in
                if case PromiseError.BrokenPromise = error where error is PromiseError {
                } else {
                    XCTFail("Invalid kind of error: \(String(reflecting: error)))")
                }
                expect.fulfill()
            }
            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.05 * Double(NSEC_PER_SEC)))
            dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                promise
            }
        }
        waitForExpectationsWithTimeout(0.4, handler: nil)
    }
    

    
    func testPromiseChainShouldNotDeallocatePrematurely() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let promise = Promise<String>()
            let future = promise.future!
            future.then { str -> String in
                usleep(1000)
                return "1"
            }
            .then { str in
                "2"
            }
            .then { str in
                expect.fulfill()
            }

            dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                promise.fulfill("OK")
            }
        }
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testPromiseFulfillingAPromiseShouldInvokeSuccessHandler() {
        let promise = Promise<String>()
        let future = promise.future!
        let expect = self.expectationWithDescription("future should be fulfilled")
        future.then { str -> () in
            XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testPromiseFulfillingAPromiseShouldNotInvokeFailureHandler() {
        let promise = Promise<String>()
        let future = promise.future!
        let expect = self.expectationWithDescription("future should be fulfilled")
        future.recover { str -> String in
            XCTFail("Not expected")
            expect.fulfill()
            return "Fail"
        }
        .then { str -> () in
            XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testContinuationReturnsFulfilledResultAndThenInvokesNextContinuation() {
        let promise = Promise<String>()
        let future = promise.future!
        let expect = self.expectationWithDescription("future should be fulfilled")
        future.then { result -> String in
            if result == "OK" {
                return "OK"
            }
            else {
                throw TestError.Failed
            }
        }
        .then { str -> Int in
            XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
            expect.fulfill()
            return 0
        }
        .recover { err -> Int in
            return -1
        }

        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }


}
