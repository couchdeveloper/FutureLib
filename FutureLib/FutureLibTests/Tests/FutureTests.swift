//
//  FutureTests.swift
//  FutureTests
//
//  Created by Andreas Grosam on 06.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import XCTest
import FutureLib



class Dummy {
    let _expect : XCTestExpectation
    init(_ expect : XCTestExpectation) {
        _expect = expect
    }
    deinit {
        _expect.fulfill()
    }
}




/// Initialize and configure the Logger
let Log = Logger(category: "Test",
        verbosity: Logger.Severity.Info,
        executionContext: GCDSyncExecutionContext(dispatch_queue_create("logger_sync_queue", nil)!))


class Foo<T> {
    typealias ArrayClosure = ([T])->()
}

class FutureTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        #if DEBUG
            print("DEBUG")
        #endif
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    
    
    func testExample1a() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let test:()->() = {
            let promise = Promise<String>()
            let future = promise.future!
            promise.fulfill("OK")
            future.then { str -> () in
                Log.Info ("result: \(str)")
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testExample10() {
        let promise = Promise<String>()
        let expect = self.expectationWithDescription("future should be rejected")
        let test:()->() = {
            let future = promise.future!
            promise.reject(TestError.Failed)
            future.`catch` { error -> () in
                Log.Info ("result: \(error)")
                expect.fulfill()
            }
            sleep(1)
        }
        test()
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    

    func testGivenARejectedFutureWhenRegisteringFailureHandlerItShouldRunItsFailureHandler() {
        let promise = Promise<String>(error: TestError.Failed)
        let expect = self.expectationWithDescription("future should be rejected")
        let test:()->() = {
            let future = promise.future!
            //promise.reject(TestError.Failed)
            //usleep(1000)
            future.`catch` { error -> () in
                Log.Info ("result: \(error)")
                expect.fulfill()
            }
        }
        test()
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    func testGivenAFutureWithRegisteredFailureHandlerWhenRejectedItShouldRunItsFailureHandler() {
        let promise = Promise<String>()
        let expect = self.expectationWithDescription("future should be rejected")
        let test:()->() = {
            let future = promise.future!
            //promise.reject(TestError.Failed)
            //usleep(1000)
            future.`catch` { error -> () in
                Log.Info ("result: \(error)")
                expect.fulfill()
            }
        }
        test()
        promise.reject(TestError.Failed)
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }
    

    func testExample2() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then(on:GCDAsyncExecutionContext(dispatch_get_main_queue())) { str -> () in
            Log.Info ("result: \(str)")
            expect.fulfill()
        }
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testExample3() {
        let expect1 = self.expectationWithDescription("future1 should be fulfilled")
        let expect2 = self.expectationWithDescription("future2 should be fulfilled")
        let expect3 = self.expectationWithDescription("future3 should be fulfilled")
        let expect4 = self.expectationWithDescription("future4 should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        let result = future.then { str -> Int in
            Log.Info ("result 0: \(str)")
            expect1.fulfill()
            return 1
            }
        .then { x -> Int in
            Log.Info("result 1: \(x)")
            expect2.fulfill()
            return 2
        }
        .then { x -> Int in
            Log.Info("result 2: \(x)")
            expect3.fulfill()
            return 3
        }
        .then { x -> String in
            Log.Info("result 3: \(x)")
            expect4.fulfill()
            return "done"
        }
        
        Log.Info("resulting future: \(result)")
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
        //Log.Info("resulting future: \(result)")
    }
    

    func testExample4() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        future.then { str -> Int in
            Log.Info ("result 0: \(str)")
            return 1
        }
        .then { x -> Int in
            Log.Info("result 1: \(x)")
            return 2
        }
        .`catch` { err -> Int in
            Log.Info ("Error: \(err)")
            return -1
        }
        .then { x -> String in
            Log.Info("result 2: \(x)")
            return "unused"
        }
        .finally { () -> () in
            Log.Info ("**done**")
            expect.fulfill()
        }
        Log.Info("fulfill future")
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(100000, handler: nil)
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
        };
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
            cr.cancel()
        };
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
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
                cr.cancel()
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(100 * NSEC_PER_MSEC)),dispatch_get_global_queue(0,0)) {
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
                Log.Info("continuation")
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
    
    func testPromiseShouldNotDeallocatePrematurely() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            let promise = Promise<String>()
            let future = promise.future!
            future.then {  str in
                expect.fulfill()
            }
            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
            dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
                promise.fulfill("OK")
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
        future.`catch` { str -> String in
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
        future.then { result -> Result<String> in
            if true {
                return Result<String>("OK")
            }
            else {
                return Result<String>(error: TestError.Failed)
            }
        }
        .then { str -> Int in
            XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
            expect.fulfill()
            return 0
        }
        .`catch` { err -> Int in
            Log.Info ("Error: \(err)")
            return -1
        }
        
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    
    
    
    
    
    
    // MARK: - Initial Invariants
//    func testPromiseShouldInitiallyBeInPendingState()
//    {
//        let promise = Promise<Int>()
//        let future = promise.future!
//        
//        XCTAssertTrue(future.isPending == true, "future.isPending == YES");
//        XCTAssertTrue(future.isCancelled == false, "future.isCancelled == NO");
//        XCTAssertTrue(future.isFulfilled == false, "future.isFulfilled == NO");
//        XCTAssertTrue(future.isRejected == false, "future.isRejected == NO");
//    }

//    func testInitiallyResolvedPromiseShouldBeInFulfilledState()
//    {
//        let promise = Promise<Int>()
//        let promise1 = promise.future!
//        
//        XCTAssertTrue(promise1.isPending == false, "future.isPending == NO");
//        XCTAssertTrue(promise1.isCancelled == false, "future.isCancelled == NO");
//        XCTAssertTrue(promise1.isFulfilled == true, "future.isFulfilled == YES");
//        XCTAssertTrue(promise1.isRejected == false, "future.isRejected == NO");
//        
//        var promise2 = Promise<String>(result: "OK").future
//        
//        XCTAssertTrue(promise2.isPending == false, "future.isPending == NO");
//        XCTAssertTrue(promise2.isCancelled == false, "future.isCancelled == NO");
//        XCTAssertTrue(promise2.isFulfilled == true, "future.isFulfilled == YES");
//        XCTAssertTrue(promise2.isRejected == false, "future.isRejected == NO");
//    }
    
//    func testInitiallyResolvedPromiseShouldBeInRejectedState()
//    {
//        let promise1 = Promise<Int>(reason: Error()).future
//        
//        XCTAssertTrue(promise1.isPending == false, "future.isPending == NO");
//        XCTAssertTrue(promise1.isCancelled == false, "future.isCancelled == NO");
//        XCTAssertTrue(promise1.isFulfilled == false, "future.isFulfilled == NO");
//        XCTAssertTrue(promise1.isRejected == true, "future.isRejected == YES");
//    }

//    // MARK: - Once
//    
//    func testStateFulfilledOnce()
//    {
//        let promise = Promise<String>()
//        let future = promise.future!
//        deferred.resolve("OK")
//        
//        XCTAssertTrue(future.isPending == false, "future.isPending == NO")
//        XCTAssertTrue(future.isCancelled == false, "future.isCancelled == NO")
//        XCTAssertTrue(future.isFulfilled == true, "future.isFulfilled == YES")
//        XCTAssertTrue(future.isRejected == false, "future.isRejected == NO")
//        
//        deferred.resolve("NO")
//        XCTAssertTrue(future.isPending == false, "")
//        XCTAssertTrue(future.isCancelled == false, "")
//        XCTAssertTrue(future.isFulfilled == true, "")
//        XCTAssertTrue(future.isRejected == false, "")
//        
//        deferred.resolve(Error("Fail!"))
//        XCTAssertTrue(future.isPending == false, "")
//        XCTAssertTrue(future.isCancelled == false, "")
//        XCTAssertTrue(future.isFulfilled == true, "")
//        XCTAssertTrue(future.isRejected == false, "")
//        
//        future.cancel(reason: Error("Cancelled"))
//        XCTAssertTrue(future.isPending == false, "")
//        XCTAssertTrue(future.isCancelled == false, "")
//        XCTAssertTrue(future.isFulfilled == true, "")
//        XCTAssertTrue(future.isRejected == false, "")
//    }
//    
//    
//    func testStateRejectedOnce()
//    {
//        let promise = Promise<String>()
//        let future = promise.future!
//        deferred.resolve(Error("Fail!"))
//        
//        XCTAssertTrue(future.isPending == false)
//        XCTAssertTrue((future.isPending == false))
//        XCTAssertTrue(future.isCancelled == false)
//        XCTAssertTrue(future.isFulfilled == false)
//        XCTAssertTrue(future.isRejected == true)
//        
//        // try to fulfill
//        deferred.resolve("OK")
//        XCTAssertTrue(future.isPending == false)
//        XCTAssertTrue(future.isCancelled == false)
//        XCTAssertTrue(future.isFulfilled == false)
//        XCTAssertTrue(future.isRejected == true)
//        let r = future.get()
//        //XCTAssertTrue(r == Either(right: Error("Fail!")))
//        
//        deferred.resolve(Error("Other Fail!")) // trying to reject with another string value
//        XCTAssertTrue(future.isPending == false)
//        XCTAssertTrue(future.isCancelled == false)
//        XCTAssertTrue(future.isFulfilled == false)
//        XCTAssertTrue(future.isRejected == true)
//        //    XCTAssertTrue( [future.get isKindOfClass:[NSError class]]);
//        //    XCTAssertTrue([[future.get userInfo][NSLocalizedFailureReasonErrorKey] isKindOfClass:[NSString class]], @"");
//        //    XCTAssertTrue([[future.get userInfo][NSLocalizedFailureReasonErrorKey] isEqualToString:@"Fail"], @"");
//        //
//        //    [future cancelWithReason:@"Cancelled"];
//        //    XCTAssertTrue(future.isPending == false, @"");
//        //    XCTAssertTrue(future.isCancelled == false, @"");
//        //    XCTAssertTrue(future.isFulfilled == false, @"");
//        //    XCTAssertTrue(future.isRejected == true, @"");
//        //    XCTAssertTrue( [future.get isKindOfClass:[NSError class]], @"");
//        //    XCTAssertTrue([[future.get userInfo][NSLocalizedFailureReasonErrorKey] isKindOfClass:[NSString class]], @"");
//        //    XCTAssertTrue([[future.get userInfo][NSLocalizedFailureReasonErrorKey] isEqualToString:@"Fail"], @"");
//    }

}
