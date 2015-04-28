//
//  FutureTests.swift
//  FutureTests
//
//  Created by Andreas Grosam on 06.09.14.
//  Copyright (c) 2014 Andreas Grosam. All rights reserved.
//

import XCTest
import Future


class FutureTests2: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
//    func testInitDealloc() {
//        // This is an example of a functional test case.
//        let future = Promise<Int>().future
//    }
    
//    func testExample1() {
//        let expect = self.expectationWithDescription("future should be fulfilled")
//        let test:()->() = {
//            let promise = Promise<String>()
//            let future = promise.future
//            promise.fulfill("OK")
//            future.then {
//                str -> () in
//                println ("result: \(str)")
//                expect.fulfill()
//            }
//        }
//        test()
//        self.waitForExpectationsWithTimeout(1, handler: nil)
//    }

//    func testExample2() {
//        let expect = self.expectationWithDescription("future should be fulfilled")
//        let promise = Promise<String>()
//        let future = promise.future
//        future.then(on:dispatch_get_main_queue()) {
//            str -> () in
//            println ("result: \(str)")
//            expect.fulfill()
//        }
//        promise.fulfill("OK")
//        waitForExpectationsWithTimeout(1, handler: nil)
//    }

    func testExample3() {
        let expect = self.expectationWithDescription("future should be fulfilled")
        let promise = Promise<String>()
        let future = promise.future!
        
        let onFinally = { ()->() in println ("**done**"); expect.fulfill() }
        
        future.then { str -> Int in
            println ("result 0: \(str)")
            return 1
        }
        .then { x -> Int in
            println("result 1: \(x)")
            return 2
        }
        .catch { err -> Int in
            println ("Error: \(err)")
            return -1
        }
        .then { x -> String in
            println("result 2: \(x)")
            return "unused"
        }
//        .finally(cancellationToken:nil)  { ()->() in
//            println ("**done**")
//            expect.fulfill()
//        }
        .finally(cancellationToken:nil) {
            onFinally()
        }
        
        
        promise.fulfill("OK")
        waitForExpectationsWithTimeout(2000000, handler: nil)
        //        let runLoop = NSRunLoop.mainRunLoop()
        //        runLoop.run()
        //
    }

//    // Livetime
//    
//    func testPromiseShouldNotDeallocatePrematurely() {
//        let sem = dispatch_semaphore_create(0)
//        let expect = self.expectationWithDescription("future should be fulfilled")
//        dispatch_async(dispatch_get_global_queue(0, 0)) {
//            let promise = Promise<String>()
//            let future = promise.future
//            future.then {
//                str in
//                expect.fulfill()
//            }
//            let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
//            dispatch_after(delay, dispatch_get_global_queue(0, 0)) {
//                deferred.resolve("OK")
//            }
//        }
//        
//        waitForExpectationsWithTimeout(0.4, handler: nil)
//    }
//    
//    func testPromiseChainShouldNotDeallocatePrematurely() {
//        let sem = dispatch_semaphore_create(0)
//        let expect = self.expectationWithDescription("future should be fulfilled")
//        let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
//        dispatch_async(dispatch_get_global_queue(0, 0)) {
//            let promise = Promise<String>()
//            let future = promise.future
//            future.then {
//                str in
//                "1"
//                }
//                .then {
//                    str in
//                    "2"
//                }
//                .then {
//                    str in
//                    expect.fulfill()
//            }
//            
//            dispatch_after(delay, dispatch_get_global_queue(0, 0)) {
//                deferred.resolve("OK")
//            }
//        }
//        
//        waitForExpectationsWithTimeout(0.4, handler: nil)
//    }
//    
//    
//    func testPromiseFulfillingAPromiseShouldInvokeSuccessHandler() {
//        let promise = Promise<String>()
//        let future = promise.future
//        let expect = self.expectationWithDescription("future should be fulfilled")
//        future.then {
//            str -> () in
//            XCTAssertEqual("OK", str, "Input value should be equal \"OK\"")
//            expect.fulfill()
//        }
//        deferred.resolve("OK")
//        waitForExpectationsWithTimeout(0.2, handler: nil)
//    }
//    
//    func testPerformanceOneContinuation() {
//        self.measureBlock() {
//            let sem = dispatch_semaphore_create(0)
//            let promise = Promise<String>()
//            let future = promise.future
//            future.then {
//                str -> () in
//                dispatch_semaphore_signal(sem)
//                ()
//            }
//            deferred.resolve("OK")
//            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
//        }
//    }
//    func testPerformanceTwoContinuations() {
//        self.measureBlock() {
//            let sem = dispatch_semaphore_create(0)
//            let promise = Promise<String>()
//            let future = promise.future
//            future.then {
//                str -> Int in
//                return 1
//                }
//                .then {
//                    str -> () in
//                    dispatch_semaphore_signal(sem); ()
//            }
//            
//            deferred.resolve("OK")
//            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
//            //println("|")
//        }
//    }
//    func testPerformanceThreeContinuations() {
//        self.measureBlock() {
//            let sem = dispatch_semaphore_create(0)
//            let promise = Promise<String>()
//            let future = promise.future
//            future.then { str -> Int in
//                return 1
//                }
//                .then { str -> Int in
//                    return 2
//                }
//                .then { str -> () in
//                    dispatch_semaphore_signal(sem); ()
//            }
//            
//            deferred.resolve("OK")
//            dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER)
//            //println("|")
//        }
//    }
//    
//    
//    // MARK: - Initial Invariants
//    
//    func testPromiseShouldInitiallyBeInPendingState()
//    {
//        let promise = Promise<Int>()
//        let future = promise.future
//        
//        XCTAssertTrue(future.isPending == true, "future.isPending == YES");
//        XCTAssertTrue(future.isCancelled == false, "future.isCancelled == NO");
//        XCTAssertTrue(future.isFulfilled == false, "future.isFulfilled == NO");
//        XCTAssertTrue(future.isRejected == false, "future.isRejected == NO");
//    }
//    
//    func testInitiallyResolvedPromiseShouldBeInFulfilledState()
//    {
//        let promise = Promise<Int>()
//        let promise1 = promise.future
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
//    
//    func testInitiallyResolvedPromiseShouldBeInRejectedState()
//    {
//        let promise1 = Promise<Int>(reason: Error()).future
//        
//        XCTAssertTrue(promise1.isPending == false, "future.isPending == NO");
//        XCTAssertTrue(promise1.isCancelled == false, "future.isCancelled == NO");
//        XCTAssertTrue(promise1.isFulfilled == false, "future.isFulfilled == NO");
//        XCTAssertTrue(promise1.isRejected == true, "future.isRejected == YES");
//    }
//    
//    
//    
//    
//    // MARK: - Once
//    
//    func testStateFulfilledOnce()
//    {
//        let promise = Promise<String>()
//        let future = promise.future
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
//        let future = promise.future
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
